//
//  MovesTableViewCell.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/11.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "MovesTableViewCell.h"

@implementation MovesTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setData:(NSString *)name desc:(NSString *)desc thumb:(NSString *)url {
	self.name.text = name;
	self.desc.text = desc;
	[self.thumb requestSImageWithURL:url];
//	self.thumb.yy_imageURL = [NSURL URLWithString:url];
}

@end
