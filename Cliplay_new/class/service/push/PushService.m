//
//  PushService.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/19.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "PushService.h"
#import "BPush.h"
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
#import "UIViewController+Utils.h"
#import "AutoRotateNavController.h"

#define pushApiKey @"10YipKN8jSfOn0t5e1NbBwXl"
#define pushCat    @"cliplay"

@interface PushService ()
@property NSString *pushID;
@property NSString *header;
@property BOOL isBackGroundActivateApplication;
@end

@implementation PushService

- (void)initNotification:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
		UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
		
		[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
							  completionHandler:^(BOOL granted, NSError * _Nullable error) {
								  // Enable or disable features based on authorization.
								  if (granted) {
									  [application registerForRemoteNotifications];
								  }
							  }];
#endif
	}
	else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
		UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
		
		UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
		[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
	}else {
		UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound;
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
	}
	
	// 在 App 启动时注册百度云推送服务，需要提供 Apikey
	
#ifdef DEBUG
	[BPush registerChannel:launchOptions apiKey:pushApiKey pushMode:BPushModeDevelopment withFirstAction:@"打开" withSecondAction:nil withCategory:pushCat useBehaviorTextInput:NO isDebug:YES];
#else
	[BPush registerChannel:launchOptions apiKey:pushApiKey pushMode:BPushModeProduction withFirstAction:@"打开" withSecondAction:nil withCategory:pushCat useBehaviorTextInput:NO isDebug:NO];
#endif
	
	[BPush disableLbs];
	
	// App 是用户点击推送消息启动
	NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (userInfo) {
		[BPush handleNotification:userInfo];
	}
	
	//角标清0
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)registerNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"test:%@",deviceToken);
	[BPush registerDeviceToken:deviceToken];
	[BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
		// 需要在绑定成功后进行 settag listtag deletetag unbind 操作否则会失败
		
		// 网络错误
		if (error) {
			return ;
		}
		if (result) {
			// 确认绑定成功
			if ([result[@"error_code"]intValue]!=0) {
				return;
			}
			// 获取channel_id
			NSString *myChannel_id = [BPush getChannelId];
			NSLog(@"==%@",myChannel_id);
			
			[BPush listTagsWithCompleteHandler:^(id result, NSError *error) {
				if (result) {
					NSLog(@"result ============== %@",result);
				}
			}];
			[BPush setTag:@"Mytag" withCompleteHandler:^(id result, NSError *error) {
				if (result) {
					NSLog(@"设置tag成功");
				}
			}];
		}
	}];
}

- (void)application:(UIApplication *)application receiveNotification:(NSDictionary *)userInfo
{

	// 打印到日志 textView 中
	NSLog(@"********** iOS7.0之后 background **********");
	
	NSLog(@"didReceiveRemoteNotification");
	
	_pushID = userInfo[@"push_id"];
	_header = userInfo[@"header"];
	
	// 应用在前台，不跳转页面，让用户选择。
	if (application.applicationState == UIApplicationStateActive) {
		NSLog(@"acitve ");
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Recent News", @"Push") message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Push") otherButtonTitles:NSLocalizedString(@"View", @"Push"), nil];
		[alertView show];
	}
	//杀死状态下，直接跳转到跳转页面。
	if (application.applicationState == UIApplicationStateInactive && !_isBackGroundActivateApplication)
	{
		
		[self fetchData];
		NSLog(@"applacation is unactive ===== %@",userInfo);
	}
	// 应用在后台。当后台设置aps字段里的 content-available 值为 1 并开启远程通知激活应用的选项
	if (application.applicationState == UIApplicationStateBackground) {
		NSLog(@"background is Activated Application ");
		// 此处可以选择激活应用提前下载邮件图片等内容。
		_isBackGroundActivateApplication = YES;
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Recent News", @"Push") message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Push") otherButtonTitles:NSLocalizedString(@"View", @"Push"), nil];
		[alertView show];
	}
	
	NSLog(@"%@",userInfo);
}

- (void)applicationPrior70:(UIApplication *)application receiveNotification:(NSDictionary *)userInfo {
	// App 收到推送的通知
	[BPush handleNotification:userInfo];
	NSLog(@"********** ios7.0之前 **********");
	
	_pushID = userInfo[@"push_id"];
	_header = userInfo[@"header"];
	
	// 应用在前台 或者后台开启状态下，不跳转页面，让用户选择。
	if (application.applicationState == UIApplicationStateActive || application.applicationState == UIApplicationStateBackground) {
		NSLog(@"acitve or background");
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Recent News", @"Push") message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Push") otherButtonTitles:NSLocalizedString(@"View", @"Push"), nil];
		[alertView show];
	}
	else //if(webViewLaunched)//杀死状态下，直接跳转到跳转页面。
	{
		[self fetchData];
	}
	
	NSLog(@"%@",userInfo);
}

- (void)showLocalNotificaion:(UILocalNotification *)notification {
	[BPush showLocalNotificationAtFront:notification identifierKey:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self fetchData];
	}
}

- (void)fetchData {
//	__weak typeof(self) _self = self;
//	[Helper performBlock:^{
//		[_self showPushFeed];
//	} afterDelay:0.5];
	[self showPushFeed];
}

- (void)showPushFeed {
	
//	if(!_pushID) return;
	_pushID = @"post_player_kobe_bryant_move_dunk";
	_header = @"Title";
	
	UIViewController *currentVC = [UIViewController currentViewController];
	
	NSString *header = self.header;
	NSString *pushID = self.pushID;
	
	[[CBLService sharedManager] fetchNewsByID:pushID completionHandlder:^(id<Content> content) {
		ClipController *vc = [ClipController new];
		vc.content = content;
		vc.summary = content.headline;
		vc.header = header;
		vc.postID = pushID;
		
		vc.modalPresentationStyle = UIModalPresentationCurrentContext;
		
		AutoRotateNavController *navigationController =
		[[AutoRotateNavController alloc] initWithRootViewController:vc];
		
		[currentVC presentViewController:navigationController animated:YES completion:nil];
	}];
	
	self.pushID = nil;
	self.header = nil;
}

#pragma mark - Help


@end
