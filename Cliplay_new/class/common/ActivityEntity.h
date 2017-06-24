//
//  ActivityEntity.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/14.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "ImageEntity.h"

@interface ActivityEntity : ImageEntity
@property NSString *time;
@property NSString *name;
@property NSString *avatar;
@property NSNumber *vote;
@property NSNumber *myVote;
- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc time:(NSString *)time name:(NSString *)name avatar:(NSString *)avatar vote:(NSNumber *)vote myVote:(NSNumber *)myvote;
@end
