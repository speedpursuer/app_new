//
//  ListTableViewCell.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/23.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "ListTableViewCell.h"

@implementation ListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
	self.thumb.backgroundColor = [UIColor colorWithRed:232.0 / 255.0 green:232.0 / 255.0 blue:232.0 / 255.0 alpha:1];
	self.thumb.contentMode = UIViewContentModeScaleAspectFill;
	self.thumb.layer.masksToBounds = YES;
}

- (void)setCellData:(NSString *)url name:(NSString *)name desc:(NSString *)desc {
	self.title.text = name;
	self.desc.text = desc;
	[self.thumb requestSImageWithURL:url];
}

@end
