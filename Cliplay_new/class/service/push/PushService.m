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
#import "AppDelegate.h"

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
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:@"最新消息" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"观看", nil];
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
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:@"最新消息" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"观看", nil];
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
		UIAlertView *alertView =[[UIAlertView alloc]initWithTitle:@"收到一条消息" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
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
		__weak typeof(self) _self = self;
		[Helper performBlock:^{
			[_self fetchData];
		} afterDelay:0.5];
	}
}

- (void)fetchData {
	
	if(!_pushID) return;
	
//	UIViewController *c = [UIViewController rootViewController];
	
//	UITabBarController *[(AppDelegate *)[[UIApplication sharedApplication] delegate] recordRootVC:self]
	
	UINavigationController *currentNav = [(AppDelegate *)[[UIApplication sharedApplication] delegate] rootViewController].selectedViewController;	
	UIViewController *currentVC = [UIViewController currentViewController];
	
	if([currentVC isKindOfClass:[ClipController class]]) {
		if([currentVC.parentViewController isKindOfClass:[UINavigationController class]]) {
			[(UINavigationController *)currentVC.parentViewController popViewControllerAnimated:NO];
		}
	}
	
	NSString *header = self.header;
	NSString *pushID = self.pushID;
	
	[[CBLService sharedManager] fetchNewsByID:pushID completionHandlder:^(id<Content> content) {
		ClipController *vc = [ClipController new];
		vc.content = content;
		vc.header = header;
		[currentNav pushViewController:vc animated:YES];
	}];
	
	self.pushID = nil;
	self.header = nil;
	
//	NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/", cbserverURL] stringByAppendingString: pushID]];
//	NSURLRequest *request = [NSURLRequest requestWithURL:url];
//	[NSURLConnection sendAsynchronousRequest:request
//									   queue:[NSOperationQueue mainQueue]
//						   completionHandler:^(NSURLResponse *response,
//											   NSData *data, NSError *connectionError)
//	 {
//		 if (data.length > 0 && connectionError == nil)
//		 {
//			 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
//																  options:0
//																	error:NULL];
//			 
//			 ClipController *vc = [ClipController new];
//			 vc.header = header;
//			 vc.postID = pushID;
//			 vc.showInfo = false;
//			 vc.articleDicts = dict[@"image"];
//			 vc.summary = dict[@"summary"];
//			 
////			 [_nv pushViewController:vc animated:YES];			 
////			 [_nv setNavigationBarHidden:NO];
//		 }
//	 }];
//}
//
// }];
}

#pragma mark - Help


@end
