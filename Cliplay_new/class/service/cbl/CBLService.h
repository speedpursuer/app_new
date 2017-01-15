//
//  CBLService.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/23.
//
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import "Album.h"
#import "Favorite.h"
#import "AlbumSeq.h"
#import "News.h"
#import "Player.h"
#import "Move.h"
#import "NewsTableViewController.h"

#define kDBName @"cliplay"
#define kStorageType kCBLForestDBStorage
#define kDidSynced @"didSynced"
#define kAlbumListChange @"albumModified"
#define kContentUpdate @"contentUpdated"
#define kContentDBName @"cliplay_content"
#define kDBFileType @"cblite2"

@interface CBLService : NSObject
@property (strong, nonatomic, readonly) CBLDatabase *database;
@property (strong, nonatomic, readonly) CBLDatabase *contentDatabase;
@property (strong, nonatomic, readonly) Favorite *favorite;
@property (strong, nonatomic, readonly) AlbumSeq *albumSeq;
@property (strong, nonatomic, readonly) NSArray *news;
@property (strong, nonatomic, readonly) NSArray *players;
@property (weak) NewsTableViewController *delegate;
+ (id)sharedManager;


#pragma mark - Content
- (NSArray *)movesForPlayer:(Player *)player;
- (Post *)clipsForPlayer:(Player*) player withMove:(Move *)move;
- (NSArray *)newsForPlayer:(Player*) player;
- (void)syncStartWithDelegate:(NewsTableViewController *)delegate;
#pragma mark - Album
- (Album *)creatAlubmWithTitle:(NSString*)title;
- (BOOL)deleteAlbum:(Album *)album;
- (BOOL)addClip:(NSString *)url toAlum:(Album *)album withDesc:(NSString *)desc;
- (BOOL)addClips:(NSArray *)urls toAlum:(Album *)album;
- (BOOL)modifyClipDesc:(NSString *)newDesc withIndex:(NSInteger)index forAlbum:(Album *)album;
- (BOOL)updateAlbumInfo:(NSString *)newTitle withDesc:(NSString *)newDesc forAlbum:(Album *)album;
- (BOOL)deleteClipWithIndex: (NSInteger)index forAlbum:(Album *)album;
- (NSArray *)getAllAlbums;

#pragma mark - Album order
- (BOOL)saveAlbumSeq:(NSArray *)albumIDs;

#pragma mark - Favorite
- (BOOL)isFavoriate:(NSString *)url;
- (void)setFavoriate:(NSString *)url;
- (void)unsetFavoriate:(NSString *)url;

#pragma mark - Sync
- (void)syncToRemote;
- (void)syncFromRemote;
//- (BOOL)didSyced;

#pragma mark - for test
- (void)getAllDocument;
- (CBLQuery *)queryAllAlbums;
@end
