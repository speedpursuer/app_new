//
//  PostTableViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/13.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARSegmentPageController.h"
#import "Player.h"

@interface PostTableViewController : UITableViewController <ARSegmentControllerDelegate>
@property Player *player;
@end
