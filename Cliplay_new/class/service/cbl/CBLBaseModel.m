//
//  CBLBaseModel.m
//  Cliplay
//
//  Created by 邢磊 on 2016/12/13.
//
//

#import "CBLBaseModel.h"
#define kTypeKeyword @"type"

@implementation CBLBaseModel
@dynamic owner;

+ (CBLBaseModel *)getModelInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid {
	NSString *docID = [[self class] docID:uuid];
	CBLDocument* doc = database[docID];
	CBLBaseModel *model = (CBLBaseModel *)[[self class] modelForDocument: doc];
	model.type = [[self class] docType];
	model.owner = [[self class] owner:uuid];
	return model;
}

- (NSString *)docID {
	return self.document.documentID;
}

+ (NSString*) owner:(NSString *)uuid {
	return [NSString stringWithFormat:@"user_%@", uuid];
}

// Subclasses must override the followings:
+ (NSString*) docType {
	NSAssert(NO, @"Unimplemented docType method +[%@ docType]", [self class]);
	return nil;
}

+ (NSString*) docID:(NSString *)uuid {
	NSAssert(NO, @"Unimplemented docID method +[%@ docType]", [self class]);
	return nil;
}
@end
