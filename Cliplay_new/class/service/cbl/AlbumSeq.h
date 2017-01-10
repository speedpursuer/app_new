//
//  AlbumSeq.h
//  Cliplay
//
//  Created by 邢磊 on 2016/12/29.
//
//

#import "CBLBaseModelConflict.h"

@interface AlbumSeq : CBLBaseModelConflict
@property (readwrite) NSArray *albumIDs;
+ (AlbumSeq*) getAlbumSeqInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid;
- (BOOL)saveAlbumSeq:(NSArray *)albumIDs;
- (BOOL)addAlbumID:(NSString *)newAlbumID;
- (BOOL)deleteAlbumID:(NSString *)deletedAlbumID;
@end
