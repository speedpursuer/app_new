//
//  CustomHeaderViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/12.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "ARSegmentPageController.h"

@interface PlayerViewController : ARSegmentPageController
@property Player *player;
- (instancetype) init NS_UNAVAILABLE;
- (instancetype)initWithPlayer:(Player *)player;
@end
