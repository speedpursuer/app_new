//
//  CacheSettingViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/17.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CacheSettingViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISlider *cacheLimit;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end
