//
//  Client.m
//  Cliplay
//
//  Created by 邢磊 on 16/8/4.
//
//

#import "User.h"

@implementation User
- (instancetype)init {
	if (self = [super init]) {
		_commentAccountID = @"";
		_commentName = @"";
		_commentAvatar = @"";
		_shareAccountID = @"";
		_shareWBRefreshToken = @"";
		_shareWBAccessToken = @"";
	}
	return self;
}
@end
