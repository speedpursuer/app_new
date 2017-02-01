//
//  Helper.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/19.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "Helper.h"

@implementation Helper
+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

+ (UIImage *)createImageWithColor: (UIColor *) color {
	CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return theImage;
}

@end
