//
//  Helper.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/19.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject
+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay;
@end
