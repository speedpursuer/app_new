//
//  SlowPlayViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/23.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlowPlayViewController : UIViewController
@property (weak, nonatomic) IBOutlet YYAnimatedImageView *imageView;
@property NSString *url;
- (BOOL) isInLandscapeMode;
@end
