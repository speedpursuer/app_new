//
//  PlayersTableViewCell.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/10.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "PlayersTableViewCell.h"

@implementation PlayersTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellData:(NSString *)name avatar:(NSString *)avatar {
	self.name.text = name;
	[self.thumb setImageWithResizeURL:avatar
				 usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//	self.thumb.yy_imageURL = [NSURL URLWithString:avatar];
	
//	__weak typeof(self) _self = self;
//	[self.thumb yy_setImageWithURL:[NSURL URLWithString:avatar]
//					   placeholder:nil
//						   options:YYWebImageOptionProgressive
//						  progress:nil
//						 transform:nil
//						completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
//						}
//	];
}

@end
