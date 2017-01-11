//
//  MyUIImageView.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/11.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "RoundUIImageView.h"

@implementation RoundUIImageView

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}


- (void)setup {
	self.contentMode = UIViewContentModeScaleAspectFill;
	self.clipsToBounds = YES;
	[self layoutIfNeeded];
	[self addMaskToBounds:self.frame];
}

- (void)addMaskToBounds:(CGRect)maskBounds {
	CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
	
	CGPathRef maskPath = CGPathCreateWithEllipseInRect(maskBounds, NULL);
	maskLayer.bounds = maskBounds;
	maskLayer.path = maskPath;
	maskLayer.fillColor = [UIColor blackColor].CGColor;
	
	CGPoint point = CGPointMake(maskBounds.size.width/2, maskBounds.size.height/2);
	maskLayer.position = point;
	
	[self.layer setMask:maskLayer];
	
	CGPathRelease(maskPath);
}

@end
