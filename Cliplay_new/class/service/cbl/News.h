//
//  News.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CBLBaseModel.h"
#import "ArticleEntity.h"

@interface News : CBLBaseModel
@property NSString *name;
@property NSArray *image;
@property NSString *desc;
@property NSString *thumb;
@property NSString *summary;
@end
