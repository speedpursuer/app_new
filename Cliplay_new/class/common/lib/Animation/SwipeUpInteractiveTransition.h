//
//  SwipeUpInteractiveTransition.h
//  Pods
//
//  Created by 纪洪波 on 16/3/17.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
//#import "ClipPlayController.h"
#import "SlowPlayViewController.h"

@interface SwipeUpInteractiveTransition : UIPercentDrivenInteractiveTransition
@property (nonatomic, strong) SlowPlayViewController *vc;
@property (nonatomic, assign) BOOL isInteracting;
@property (nonatomic, assign) BOOL shouldComplete;
@property (nonatomic, assign) BOOL previousIsPlaying;

- (instancetype)init:(UIViewController *)vc;
@end
