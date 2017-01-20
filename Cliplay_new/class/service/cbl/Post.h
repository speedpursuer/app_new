//
//  Post.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/13.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CBLBaseModel.h"

@interface Post : CBLBaseModel <Content>
@property NSArray *image;
@property NSString *summary;
@end
