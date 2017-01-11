//
//  PlayersTableViewCell.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/10.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YYWebImage/YYWebImage.h>
#import "RoundUIImageView.h"

@interface PlayersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet RoundUIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *name;
- (void)setCellData:(NSString *)name avatar:(NSString *)avatar;
@end
