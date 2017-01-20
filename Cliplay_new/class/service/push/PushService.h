//
//  PushService.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/19.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushService : NSObject <UIAlertViewDelegate>

- (void)initNotification:(UIApplication *)application withOptions:(NSDictionary *)launchOptions;

- (void)registerNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)application:(UIApplication *)application receiveNotification:(NSDictionary *)userInfo;

- (void)applicationPrior70:(UIApplication *)application receiveNotification:(NSDictionary *)userInfo;

- (void)showLocalNotificaion:(UILocalNotification *)notification;

@end
