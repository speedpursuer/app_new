//
//  MyLBAdapter.h
//  Cliplay
//
//  Created by 邢磊 on 16/8/5.
//
//
#import <Foundation/Foundation.h>
#import "LoopBack.h"

@interface MyLBAdapter : LBRESTAdapter
- (void)setAccessToken:(NSString *)accessToken;
@end