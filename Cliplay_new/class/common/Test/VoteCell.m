//
//  VoteCell.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/8.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "VoteCell.h"
#import <FontAwesomeKit/FAKFontAwesome.h>

@implementation VoteCell

- (void)awakeFromNib {
    [super awakeFromNib];
	[self configView];
}

- (void)configView {
	CGSize size = CGSizeMake(20, 20);
	FAKFontAwesome *upIcon = [FAKFontAwesome thumbsOUpIconWithSize:20];
	UIImage *upImg = [upIcon imageWithSize:size];
	[_upVote setImage:upImg forState:UIControlStateNormal];
	[_upVote setImage:upImg forState:UIControlStateHighlighted];
	[_upVote addTarget:self action:@selector(vote) forControlEvents:UIControlEventTouchUpInside];
	
	FAKFontAwesome *downIcon = [FAKFontAwesome thumbsODownIconWithSize:20];
	UIImage *downImg = [downIcon imageWithSize:size];
	[_downVote setImage:downImg forState:UIControlStateNormal];
	[_downVote setImage:downImg forState:UIControlStateHighlighted];
	[_upVote addTarget:self action:@selector(vote) forControlEvents:UIControlEventTouchUpInside];
}

- (void)vote {
	
}

- (void)setCellData:(NSString *)thumb name:(NSString *)name desc:(NSString *)desc time:(NSString *)time{
	self.thumb.yy_imageURL = [NSURL URLWithString:thumb];
	self.userName.text = name;
	self.desc.text = desc;
	self.time.text = time;
	[self layoutIfNeeded];
}

@end
