//
//  ClipPlayController.h
//  Cliplay
//
//  Created by 邢磊 on 16/1/14.
//
//

#import <UIKit/UIKit.h>
#import "ClipController.h"

@interface ClipPlayController : UIViewController
@property (nonatomic, strong) NSString *clipURL;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) BOOL showLike;
@property (nonatomic, weak) ClipController *delegate;
@property (nonatomic, assign) BOOL standalone;
- (void) cancelAction;
@end
