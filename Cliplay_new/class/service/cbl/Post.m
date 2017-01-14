//
//  Post.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/13.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "Post.h"
#import "ArticleEntity.h"

@implementation Post
@dynamic image, summary;
+(Class)imageItemClass {
	return [ArticleEntity class];
}
@end
