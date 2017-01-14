//
//  PlayerBanner.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/14.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARSegmentPageController.h"

@interface PlayerBanner : UIView<ARSegmentPageControllerHeaderProtocol>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *playerName;
- (void)setName:(NSString *)name;
@end
