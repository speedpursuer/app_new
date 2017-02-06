//
//  AppDelegate.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/8.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "AppDelegate.h"
#import "PushService.h"
#import <Fingertips/MBFingerTipWindow.h>

@interface AppDelegate ()
@property LBService *service;
@property CBLService *lblService;
@property PushService *pushService;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self setupTheme];
	[self loadService];
	[self.pushService initNotification:application withOptions:launchOptions];
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	[_lblService syncToRemote];
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	[_lblService syncToRemote];
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Custom Init
- (void)loadService {
	_service = [LBService sharedManager];
	_lblService = [CBLService sharedManager];
	_pushService = [PushService new];
}

- (void)setupTheme {
	[[UINavigationBar appearance] setTintColor: [UIColor whiteColor]];
	[[UINavigationBar appearance] setBarTintColor:CLIPLAY_COLOR_NAV];
	[[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
	[[UINavigationBar appearance] setTranslucent:YES];
	//Segment control
	[[UISegmentedControl appearance] setTintColor:CLIPLAY_COLOR];
	[[UISlider appearance] setTintColor:CLIPLAY_COLOR];
	[[UIButton appearance] setTintColor:CLIPLAY_COLOR];
}

#pragma mark - Social Login

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
	if (!url) {
		return NO;
	}
	return [_service handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	return [_service handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
	if (!url) {
		return NO;
	}
	return [_service handleOpenURL:url];
}

#pragma mark - Push Notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[_pushService registerNotificationsWithDeviceToken:deviceToken];
}

// 在 iOS8 系统中，还需要添加这个方法。通过新的 API 注册推送服务
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	[application registerForRemoteNotifications];
}

// 当 DeviceToken 获取失败时，系统会回调此方法
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"DeviceToken not received，reason：%@",error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	[_pushService application:application receiveNotification:userInfo];
	completionHandler(UIBackgroundFetchResultNewData);
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[_pushService applicationPrior70:application receiveNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	[_pushService showLocalNotificaion:notification];
}

#pragma mark - Rotation

- (UIInterfaceOrientationMask)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window {
	UIViewController *rootController = self.window.rootViewController;
	if([rootController isKindOfClass:[UITabBarController class]]) {
		return [((UITabBarController *)rootController).selectedViewController supportedInterfaceOrientations];
	}else {
		return UIInterfaceOrientationMaskPortrait;
	}
}

#pragma mark - Finger for demo
//- (UIWindow *)window {
//	if (!_window) {
//		MBFingerTipWindow *win = [[MBFingerTipWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//		[win setAlwaysShowTouches:YES];
//		[win setTouchImage:[UIImage imageNamed:@"finger"]];
//		[win setTouchAlpha:1.0];
//		_window = win;
//	}
//	return _window;
//}

@end
