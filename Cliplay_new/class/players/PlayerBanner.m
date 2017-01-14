//
//  PlayerBanner.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/14.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "PlayerBanner.h"

@implementation PlayerBanner
@synthesize imageView;

-(void)awakeFromNib {
	[super awakeFromNib];
}

- (UIImageView *)backgroundImageView {
	return self.imageView;
}

- (void)setName:(NSString *)name {
	[_playerName setText:name];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
