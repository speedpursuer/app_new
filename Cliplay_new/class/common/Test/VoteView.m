//
//  VoteView.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/8.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "VoteView.h"

@implementation VoteView
- (instancetype)initWithFrame:(CGRect)frame {
	return [super initWithFrame:frame];
}

- (void)setDescText:(NSString *)desc {
	_desc.text = desc;
//	[_desc sizeToFit];
	[self layoutIfNeeded];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
