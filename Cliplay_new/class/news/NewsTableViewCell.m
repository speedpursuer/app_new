//
//  NewsTableViewCell.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "NewsTableViewCell.h"

@implementation NewsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
	_thumb.layer.masksToBounds = YES;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellData:(NSString *)url name:(NSString *)name desc:(NSString *)desc {
	self.shortDesc.text = name;
	self.longDesc.text = desc;
	self.thumb.yy_imageURL = [NSURL URLWithString:url];
//	[self.thumb yy_setImageWithURL:[NSURL URLWithString:url] options:YYWebImageOptionProgressiveBlur |YYWebImageOptionSetImageWithFadeAnimation];
}

@end
