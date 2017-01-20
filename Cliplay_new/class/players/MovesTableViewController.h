//
//  MovesTableViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/11.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARSegmentPageController.h"

@interface MovesTableViewController : UITableViewController <ARSegmentControllerDelegate>
@property Player *player;
@end
