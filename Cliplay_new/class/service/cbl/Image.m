//
//  Image.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/30.
//
//

#import "Image.h"

@implementation Image
- (instancetype) initWithJSON: (id)jsonObject {
	if (self = [super init]) {
		self.desc = [jsonObject objectForKey:@"desc"];
		self.url = [jsonObject objectForKey:@"url"];
	}
	return self;
}
- (id) encodeAsJSON {
	return @{
				@"desc":self.desc,
				@"url":self.url
			};
}
@end
