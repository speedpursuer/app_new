//
//  Configuration.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/20.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "Configuration.h"

@implementation Configuration
- (void)initValue {
	_cacheLimit = [NSNumber numberWithInt:1000];
	_displayRatio = [NSNumber numberWithFloat:(float)3/4];
}
@end
