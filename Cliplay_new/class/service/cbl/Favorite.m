//
//  Favorite.m
//  Cliplay
//
//  Created by 邢磊 on 2016/12/1.
//
//

#import "Favorite.h"

#define kFavoriteDocType @"favorite"

@implementation Favorite

@dynamic clips;

+ (NSString*) docType {
	return kFavoriteDocType;
}

+ (NSString*) docID:(NSString *)uuid {
	return [NSString stringWithFormat:@"favorite_%@", uuid];
}

-(void)setInitialValue {
	self.clips = @[];
}

+ (Favorite*) getFavoriteInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid {
	Favorite *favorite = (Favorite *)[super getModelInDatabase:database withUUID:uuid];
	return favorite;
}

- (BOOL)isFavoriate:(NSString *)url {
	return ([self.clips indexOfObject:url] != NSNotFound);
}

- (void)setFavoriate:(NSString *)url {
	if(![self isFavoriate:url]) {
		[self updateFavorite:url forAdd:YES];
	}
}

- (void)unsetFavoriate:(NSString *)url {
	if([self isFavoriate:url]) {
		[self updateFavorite:url forAdd:NO];
	}
}

- (void)updateFavorite:(NSString *)url forAdd:(BOOL)isAdd {
	NSMutableArray *list = [self.clips mutableCopy];
	if(isAdd) {
		[list insertObject:url atIndex: 0];
	}else {
		[list removeObject:url];
	}
	self.clips = [list copy];
	NSError* error;
	[self save: &error];
}

@end
