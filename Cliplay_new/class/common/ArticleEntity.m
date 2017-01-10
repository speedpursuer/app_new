//
//  ArticleEntity.m
//  Cliplay
//
//  Created by 邢磊 on 16/4/1.
//
//

#import "ArticleEntity.h"

@implementation ArticleEntity

- (instancetype)initWithURL:(NSString *)url
{
	return [self initWithData:url desc:nil tag:-1];
}

- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc
{
	return [self initWithData:url desc:desc tag:-1];
}

- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc tag:(NSInteger)tag
{
	self = super.init;
	if (self) {
		_desc = desc;
		_url = url;
		_tag = tag;
	}
	return self;
}

- (instancetype)initWithCopy:(ArticleEntity *)entity
{
	self = super.init;
	if (self) {
		_desc = entity.desc;
		_url = entity.url;
		_tag = entity.tag;
	}
	return self;
}


- (instancetype)initWithJSON: (id)jsonObject {
	if (self = [super init]) {
		self.desc = [jsonObject objectForKey:@"desc"];
		self.url = [jsonObject objectForKey:@"url"];
	}
	return self;
}

- (id)encodeAsJSON {
	return @{
				@"desc":self.desc,
				@"url":self.url
			};
}

//- (instancetype)initWithDictionary:(NSDictionary *)dictionary
//{
//	self = super.init;
//	if (self) {
//		_desc = dictionary[@"desc"];
//		_image = dictionary[@"url"];
//	}
//	return self;
//}
@end



