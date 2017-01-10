//
//  FavoriteListTableViewCell.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/3.
//
//

#import "AlbumListTableViewCell.h"

@implementation AlbumListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
	self.badge.horizontalAlignment = LKBadgeViewHorizontalAlignmentRight;
	self.badge.textColor = [UIColor whiteColor];
	self.badge.badgeColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	self.badge.bounds = CGRectMake(0, 0, 80, 44);
	self.thumb.backgroundColor = [UIColor colorWithRed:232.0 / 255.0 green:232.0 / 255.0 blue:232.0 / 255.0 alpha:1];
	self.thumb.contentMode = UIViewContentModeScaleAspectFill;
	self.thumb.layer.masksToBounds = YES;
}
@end
