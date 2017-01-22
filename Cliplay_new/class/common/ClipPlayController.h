//
//  ClipPlayController.h
//  Cliplay
//
//  Created by 邢磊 on 16/1/14.
//
//

#import <UIKit/UIKit.h>

@interface ClipPlayController : UIViewController
@property (nonatomic, strong) YYAnimatedImageView *imageView;
@property (nonatomic, strong) NSString *clipURL;
@property BOOL isInLandscapeMode;
- (void)prepareToExit;
@end
