//
//  AlbumSeq.m
//  Cliplay
//
//  Created by 邢磊 on 2016/12/29.
//
//

#import "AlbumSeq.h"

#define kAlbumSeqDocType @"albumSeq"

@implementation AlbumSeq
@dynamic albumIDs;
+ (NSString*) docType {
	return kAlbumSeqDocType;
}

+ (NSString*) docID:(NSString *)uuid {
	return [NSString stringWithFormat:@"album_%@_seq", uuid];
}

- (void)setInitialValue {
	self.albumIDs = @[];
}

+ (AlbumSeq*) getAlbumSeqInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid {
	AlbumSeq *albumSeq = (AlbumSeq *)[super getModelInDatabase:database withUUID:uuid];
	return albumSeq;
}

- (BOOL)saveAlbumSeq:(NSArray *)albumIDs {
	if([self.albumIDs isEqualToArray:albumIDs]) {
		return NO;
	}
	self.albumIDs = albumIDs;
	NSError* error;
	if ([self save: &error]) {
		return YES;
	}else {
		return NO;
	}
}

- (BOOL)addAlbumID:(NSString *)newAlbumID {
	return [self updateAlbumID:newAlbumID forNew:YES];
}

- (BOOL)deleteAlbumID:(NSString *)deletedAlbumID {
	return [self updateAlbumID:deletedAlbumID forNew:NO];
}

- (BOOL)updateAlbumID:(NSString *)albumID forNew:(BOOL)isNew {
	NSMutableArray *currAlbumIDs = [self.albumIDs mutableCopy];
	if(isNew) {
		[currAlbumIDs insertObject:albumID atIndex:0];
	}else {
		[currAlbumIDs removeObject:albumID];
	}
	return [self saveAlbumSeq:[currAlbumIDs copy]];
}

@end
