//
//  Post.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/13.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "Post.h"

@implementation Post
@dynamic image, summary;
+(Class)imageItemClass {
	return [ImageEntity class];
}
-(NSArray *)images {
	return self.image;
}
-(NSString *)headline {
	return self.summary;
}
-(void)setImages:(NSArray *)image {
	self.image = image;
}
@end
