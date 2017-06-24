//
//  ActivityEntity.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/14.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "ActivityEntity.h"

@implementation ActivityEntity
- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc time:(NSString *)time name:(NSString *)name avatar:(NSString *)avatar vote:(NSNumber *)vote myVote:(NSNumber *)myvote
{
	self = [super initWithData:url desc:desc];
	if (self) {
		_time = time;
		_name = name;
		_avatar = avatar;
		_vote = vote;
		_myVote = myvote;
	}
	return self;
}

@end
