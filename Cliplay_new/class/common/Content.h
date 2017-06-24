//
//  Content.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/19.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Content <NSObject>
- (NSArray *)images;
- (void) setImages: (NSArray *)image;
- (NSString *)headline;
@end
