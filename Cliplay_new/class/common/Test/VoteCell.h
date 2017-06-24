//
//  VoteCell.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/8.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundUIImageView.h"

@interface VoteCell : UITableViewCell
@property (weak, nonatomic) IBOutlet RoundUIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *desc;
@property (weak, nonatomic) IBOutlet UIButton *upVote;
@property (weak, nonatomic) IBOutlet UIButton *downVote;
- (void)setCellData:(NSString *)thumb name:(NSString *)name desc:(NSString *)desc time:(NSString *)time;
@end
