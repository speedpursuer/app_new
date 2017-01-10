//
//  News.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "News.h"

@implementation News
@dynamic name, image, desc, summary, thumb;

+(Class)imageItemClass {
	return [ArticleEntity class];
}
@end
