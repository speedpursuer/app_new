//
//  CBLService.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/23.
//
//

#import "CBLService.h"
#import <YYWebImage/YYWebImage.h>
#import "FCUUID.h"
#import "MRProgress.h"
#import "JDStatusBarNotification.h"
#import "Reachability.h"

//#define cbserverURL   @"http://localhost:4984/cliplay_user_data"
#define cbserverURL @"http://121.40.197.226:8000/cliplay_user_data"
#define didSyncedFlag @"didSynced"
#define kLocalFlag @"isFromLocal"


@interface CBLService()
@property (nonatomic) CBLReplication *push;
@property (nonatomic) CBLReplication *pull;
@property (nonatomic) BOOL isSynced;
@property (nonatomic) NSError *lastSyncError;
@property MRProgressOverlayView *progressView;
@property NSString *uuid;
@end
@implementation CBLService

#pragma mark - Init
+ (id)sharedManager {
	static CBLService *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}

- (instancetype)init {
	if (self = [super init]) {
		NSString *dbName = kDBName;
		
		CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
		option.create = YES;
		option.storageType = kStorageType;
		//	option.encryptionKey = kEncryptionEnabled ? kEncryptionKey : nil;
		
		NSError *error;
		_database = [[CBLManager sharedInstance] openDatabaseNamed:dbName
													   withOptions:option
															 error:&error];
		if (error)
			NSLog(@"Cannot create database with an error : %@", [error description]);
	}
	
//	[self enableLogging];
	
//	CBLModelFactory* factory = _database.modelFactory;
//	[factory registerClass:[Album class] forDocumentType:@"album"];
//	[factory registerClass:[Favorite class] forDocumentType:@"favorite"];
//	[factory registerClass:[AlbumSeq class] forDocumentType:@"albumSeq"];
	[self initContentDB];
//	[self allNews];
	[self loadFavorite];
	[self loadAlbumSeq];
	[self loadSynced];
	[self observeChanges];
	[self syncToRemote];
	
	//For test ONLY
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *applicationSupportDirectory = [paths firstObject];
	NSLog(@"applicationSupportDirectory: '%@'", applicationSupportDirectory);
	
	return self;
}

- (void)observeChanges {
	[self.favorite addObserver:self forKeyPath:@"clips" options:0 context:nil];
	[self.albumSeq addObserver:self forKeyPath:@"albumIDs" options:0 context:nil];
}

- (void)dealloc {
	[self.favorite removeObserver:self forKeyPath:@"clips"];
	[self.albumSeq removeObserver:self forKeyPath:@"albumIDs"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
					   context:(void *)context {
	[self notifyChanges];
}

- (void)notifyChanges {
	[[NSNotificationCenter defaultCenter] postNotificationName:kAlbumListChange object:nil];
}

#pragma mark - Content (News & move)
- (void)initContentDB {
	CBLDatabaseOptions *option = [[CBLDatabaseOptions alloc] init];
	option.create = YES;
	option.storageType = kStorageType;
	
	CBLManager* dbManager = [CBLManager sharedInstance];
	NSError *error;
	NSString *publicDBName = kContentDBName;
	CBLDatabase* database = [dbManager existingDatabaseNamed:publicDBName error:&error];
	
	if (!database) {
		NSString* cannedDbPath = [[NSBundle mainBundle] pathForResource:publicDBName
																 ofType:kDBFileType];
		BOOL ok = [dbManager replaceDatabaseNamed:publicDBName
								  withDatabaseDir:cannedDbPath
											error:&error];
		if (ok) {
			database = [dbManager existingDatabaseNamed:publicDBName error: &error];
		}
		if (error) {
			NSLog(@"Cannot create database with an error : %@", [error description]);
		}
	}
	_contentDatabase = database;
}

- (NSArray *)allNews {
	CBLQuery* query = [self queryAllContent];
	query.startKey = @"news_\uffff";
	query.endKey   = @"news_";
	query.descending = YES;
	
	NSError *error;
	NSMutableArray *allNews = [NSMutableArray new];
	CBLQueryEnumerator* result = [query run: &error];
	for (CBLQueryRow* row in result) {
		[allNews addObject:[News modelForDocument:row.document]];
	}
	return [allNews copy];
}

- (CBLQuery *)queryAllContent {
	CBLQuery* query = [self.contentDatabase createAllDocumentsQuery];
	return query;
}

- (NSArray *)allPlayers {
	CBLQuery* query = [self queryAllContent];
	query.startKey = @"player_";
	query.endKey   = @"player_\uffff";
	
	NSError *error;
	NSMutableArray *allPlayers = [NSMutableArray new];
	CBLQueryEnumerator* result = [query run: &error];
	for (CBLQueryRow* row in result) {
		NSInteger total = [[row.document propertyForKey:@"clip_total"] integerValue];
		if(total > 0) {
			[allPlayers addObject:[Player modelForDocument:row.document]];
		}
	}
	return [allPlayers copy];
}

- (CBLQuery *)queryAllPlayers {
	CBLView* view = [_database viewNamed: @"players"];
	
	[view setMapBlock: MAPBLOCK({
		NSString *total = doc[@"clip_total"];
		if(total) {
			NSInteger total1 = [total integerValue];
			if(total1 > 0) {
				emit(doc[@"_id"], nil);
			}
		}
		
	}) version: @"3"];
	
	CBLQuery* query = [view createQuery];
	return query;
}

#pragma mark - Album

- (Album*)creatAlubmWithTitle:(NSString*)title {
	Album* album = [Album getAlbumInDatabase:_database withTitle:title withUUID:_uuid];
	NSError *error;
	if ([album save:&error]) {
		[_albumSeq addAlbumID:[album docID]];
		[self notifyChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"已新建\"%@\"", album.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return album;
	}else {
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return nil;
	}
}

- (BOOL)deleteAlbum:(Album *)album {
	NSError *error;
	NSString *albumName = album.title;
	NSString *albumID = [album docID];
	if ([album deleteDocument:&error]){
		[_albumSeq deleteAlbumID:albumID];
		[self notifyChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"已删除\"%@\"", albumName] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else{
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (BOOL)addClip:(NSString *)url toAlum:(Album *)album withDesc:(NSString *)desc {
	
	NSMutableArray *existingClips = [NSMutableArray arrayWithArray:album.clips];
	ArticleEntity *clip = [[ArticleEntity alloc] initWithData:url desc:desc];
	
	[existingClips addObject:clip];
	album.clips = [existingClips copy];
	
	return [self saveAlbum:album];
}

- (BOOL)addClips:(NSArray *)urls toAlum:(Album *)album{
	
	NSMutableArray *existingClips = [NSMutableArray arrayWithArray:album.clips];
	
	for(NSString *url in urls) {
		ArticleEntity *clip = [[ArticleEntity alloc] initWithData:url desc:@""];
		[existingClips addObject:clip];
	}
	
	album.clips = [existingClips copy];
	
	return [self saveAlbum:album];
}

- (BOOL)modifyClipDesc:(NSString *)newDesc withIndex:(NSInteger)index forAlbum:(Album *)album {
	
	NSMutableArray *clipsToModify = [album.clips mutableCopy];
	ArticleEntity *clip = clipsToModify[index];
	ArticleEntity *newClip = [[ArticleEntity alloc] initWithCopy:clip];
	newClip.desc = newDesc;
	[clipsToModify replaceObjectAtIndex:index withObject:newClip];
	album.clips = [clipsToModify copy];
	
	NSError* error;
	if ([album save: &error]) {
		[JDStatusBarNotification showWithStatus:@"描述修改成功" dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (BOOL)deleteClipWithIndex: (NSInteger)index forAlbum:(Album *)album {
	
	NSMutableArray *clipsToModify = [album.clips mutableCopy];
	[clipsToModify removeObjectAtIndex:index];
	if(clipsToModify.count == 0) {
		[album removeThumb];
	}else if(index == 0) {
		//Change thumb if the first clip is switched
		ArticleEntity *currFirstClip = clipsToModify[0];
		[album setThumb:[self getThumb:currFirstClip.url]];
	}
	album.clips = [clipsToModify copy];
	
	NSError* error;
	if ([album save: &error]) {
		[self notifyChanges];
		[JDStatusBarNotification showWithStatus:@"动图删除成功" dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (BOOL)updateAlbumInfo:(NSString *)newTitle withDesc:(NSString *)newDesc forAlbum:(Album *)album {
	if([album.title isEqualToString:newTitle] && [album.desc isEqualToString:newDesc]){
		return NO;
	}
	album.title = newTitle;
	album.desc = newDesc;
	
	NSError* error;
	if ([album save: &error]) {
		[self notifyChanges];
		[JDStatusBarNotification showWithStatus:@"信息修改成功" dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (void)updateAlbumSeq {
	
	NSMutableArray *albumIDs = [[NSMutableArray alloc] initWithArray:_albumSeq.albumIDs];
	NSMutableArray *allAlbums = [[NSMutableArray alloc] init];
	
	CBLQuery* query = [self queryAllAlbums];
	NSError *error;
	CBLQueryEnumerator* result = [query run: &error];
	
	for (CBLQueryRow* row in result) {
		CBLDocument *doc = row.document;
		[allAlbums addObject:doc.documentID];
	}
	
	[allAlbums removeObjectsInArray:albumIDs];
	
	for(NSString *albumID in allAlbums) {
		[albumIDs addObject:albumID];
	}
	
	[self saveAlbumSeq:[albumIDs copy]];
}


- (NSArray *)getAllAlbums {
	
	CBLQuery* query = [self queryAllAlbums];
	NSError *error;
	CBLQueryEnumerator* result = [query run: &error];
	
	if(result.count != _albumSeq.albumIDs.count) {
		NSMutableArray *albums = [[NSMutableArray alloc] init];
		for (CBLQueryRow* row in result) {
			CBLDocument *doc = row.document;
			Album *album = [Album modelForDocument:doc];
			[albums addObject:album];
		}
		return [albums copy];
	}else {
		NSMutableArray *albums = [[NSMutableArray alloc] init];
		NSMutableDictionary *dict = [NSMutableDictionary new];
		for (CBLQueryRow* row in result) {
			CBLDocument *doc = row.document;
			Album *album = [Album modelForDocument:doc];
			[dict setObject:album forKey:doc.documentID];
		}
		
		for(NSString *key in _albumSeq.albumIDs) {
			id album = [dict objectForKey:key];
			if(album) {
				[albums addObject:album];
			}
		}
		return [albums copy];
	}
}

- (CBLQuery *)queryAllAlbums {
	CBLView* view = [_database viewNamed: @"albums"];
	
	view.documentType = @"album";
	[view setMapBlock: MAPBLOCK({
		emit(doc[@"_id"], nil);
	}) version: @"1"];
	
	CBLQuery* query = [view createQuery];
	query.descending = YES;
	
	return query;
}

#pragma mark - Album sequence

-(void)loadAlbumSeq {
	_albumSeq = [AlbumSeq getAlbumSeqInDatabase:_database withUUID:_uuid];
}

- (BOOL)saveAlbumSeq:(NSArray *)albumIDs {
	return [_albumSeq saveAlbumSeq:albumIDs];
//	if([_albumSeq.albumIDs isEqualToArray:albumIDs]) {
//		return NO;
//	}
//	_albumSeq.albumIDs = albumIDs;
//	NSError* error;
//	if ([_albumSeq save: &error]) {
//		return YES;
//	}else {
//		return NO;
//	}
}

#pragma mark - Favorite
- (void)loadFavorite {
	_uuid = [FCUUID uuidForDevice];
//	_uuid = @"fd5f1034aacc4a608ef6678357012f99";
	_favorite = [Favorite getFavoriteInDatabase:_database withUUID:_uuid];
}

- (BOOL)isFavoriate:(NSString *)url {
	return [_favorite isFavoriate:url];
}

- (void)setFavoriate:(NSString *)url {
	[_favorite setFavoriate:url];
}

- (void)unsetFavoriate:(NSString *)url {
	[_favorite unsetFavoriate:url];
}

#pragma mark - Logging
- (void)enableLogging {
	//        [CBLManager enableLogging:@"Database"];
	//        [CBLManager enableLogging:@"View"];
	//        [CBLManager enableLogging:@"ViewVerbose"];
	//        [CBLManager enableLogging:@"Query"];
	[CBLManager enableLogging:@"Sync"];
	[CBLManager enableLogging:@"SyncVerbose"];
	//        [CBLManager enableLogging:@"ChangeTracker"];
}

#pragma mark - Sync
- (void)syncToRemote {
	
	if(!_isSynced) return;
	
	NSURL *syncUrl = [NSURL URLWithString:cbserverURL];
	
	_push = [_database createPushReplication:syncUrl];
	
	[_database setFilterNamed: @"syncedFlag" asBlock: FILTERBLOCK({
		return ![revision[@"_id"] isEqual:didSyncedFlag];
	})];
	
	id<CBLAuthenticator> auth;
	auth = [CBLAuthenticator basicAuthenticatorWithName: @"cliplay_user"
											   password: @"Cliplay_nba"];
	_push.authenticator = auth;
	_push.filter = @"syncedFlag";
	//	_push.continuous = YES;
	
	[_push start];
}

- (void)syncFromRemote {
	
	if(_isSynced) return;
	
	NSURL *syncUrl = [NSURL URLWithString:cbserverURL];
	
	_pull = [_database createPullReplication:syncUrl];
	
	id<CBLAuthenticator> auth;
	auth = [CBLAuthenticator basicAuthenticatorWithName: @"cliplay_user"
											   password: @"Cliplay_nba"];
	_pull.authenticator = auth;
	_pull.channels = @[[NSString stringWithFormat:@"user_%@", _uuid]];
	
	NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(myReplicationProgress:)
				 name:kCBLReplicationChangeNotification object:_pull];
	
	
	[self showProgress];
	
	_lastSyncError = nil;
	
	[self performBlock:^{
		[_pull start];
	} afterDelay:0.5];
}


- (void)myReplicationProgress:(NSNotification *)notification {
	NSError* error = _pull.lastError;
	if(error){
		_lastSyncError = error;
	}
	// Repeat to report progress and show activity indicator
	if (_pull.status == kCBLReplicationActive){
//		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		double progress = 0.0;
		double total = _pull.changesCount;
		if (total > 0.0) {
			progress = _pull.completedChangesCount/ total;
		}
		
		[_progressView setProgress:progress];
	}
	else {
//		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	
	// If server not reechable, set error and stop pull
	if(_pull.status == kCBLReplicationOffline) {
		if(![self hasNetwork]) {
			if(!_lastSyncError) {
				_lastSyncError = [NSError errorWithDomain:@"Has no network" code:501 userInfo:nil];
			}
			[_pull stop];
		}
	}
	if(_pull.status == kCBLReplicationStopped) {
		if(_lastSyncError){
			[JDStatusBarNotification showWithStatus:@"同步历史数据失败，请检查网络" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		}else if(_pull.changesCount == _pull.completedChangesCount) {
			// Successfull pull means - 1. No error 2. all changes completed
			[_progressView setProgress:1.0];
			
			//Resolve conflict and mark pull complete
			if([self processConflict]) {
				[self updateAlbumSeq];
				[self setDidSynced];
			};
		}
		[self performBlock:^{
			[_progressView dismiss:NO];
		} afterDelay:0.8];
	}
}

- (void)loadSynced {
	_isSynced = ([_database existingDocumentWithID: didSyncedFlag] != nil);
}

- (void)setDidSynced {
	CBLDocument* doc = [_database documentWithID: didSyncedFlag];
	NSError* error;
	if ([doc putProperties: @{@"synced": @true} error: &error]) {
		_isSynced = YES;
	}
	[self notifyChanges];
}

//- (BOOL)didSyced {
//	return _isSynced;
//}

- (void)showProgress {
	
	MRProgressOverlayView *view = [MRProgressOverlayView showOverlayAddedTo:[UIApplication sharedApplication].keyWindow animated:NO];
	
	view.mode = MRProgressOverlayViewModeDeterminateHorizontalBar;
	
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"同步历史数据", nil) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
	
	view.titleLabelAttributedText = title;
	
	view.tintColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	
	_progressView = view;
}

- (BOOL)processConflict {
	if([self processConflictForModel:_favorite forList:@"clips"] &&
	   [self processConflictForModel:_albumSeq forList:@"albumIDs"]) {
		return YES;
	}
	return NO;
}

- (BOOL)processConflictForModel:(CBLBaseModelConflict *)model forList:(NSString *)listName {
	
	[model cleanEmptyChanges];
	
	NSError *error;
	NSArray* conflicts = [model.document getConflictingRevisions: &error];
	
	if(conflicts.count <= 1) {
		return YES;
	}
	
	CBLSavedRevision* current = model.document.currentRevision;
	NSMutableArray *local = [NSMutableArray new];
	NSMutableArray *remote = [NSMutableArray new];
	
	for (CBLSavedRevision* rev in conflicts) {
		
		NSArray *list = [rev propertyForKey:listName];
		bool isFromLocal = [[rev propertyForKey:kLocalFlag] boolValue];
		
		if(isFromLocal == YES){
			[local addObjectsFromArray:list];
		}else{
			[remote addObjectsFromArray:list];
		}
		
		if (rev != current) {
			CBLUnsavedRevision *newRev = [rev createRevision];
			newRev.isDeletion = YES;
			if(![newRev saveAllowingConflict: &error]) {
				return NO;
			}
		}
	}
	
	NSMutableOrderedSet *set = [NSMutableOrderedSet new];
	[set addObjectsFromArray:[local copy]];
	[set addObjectsFromArray:[remote copy]];
	
	CBLUnsavedRevision *newRev = [current createRevision];
	[newRev setObject:[set array] forKeyedSubscript:listName];
	
	if(![newRev saveAllowingConflict: &error]) {
		return NO;
	}
	
	return YES;
}

#pragma mark - Helper

//- (BOOL)updateAlbumSeqWithNewAlbumID:(NSString *)newAlbumID {
//	NSMutableArray *currAlbumIDs = [_albumSeq.albumIDs mutableCopy];
//	[currAlbumIDs insertObject:newAlbumID atIndex:0];
//	return [self saveAlbumSeq:[currAlbumIDs copy]];
//}
//
//- (BOOL)updateAlbumSeqWithDeletedAlbumID:(NSString *)deletedAlbumID {
//	NSMutableArray *currAlbumIDs = [_albumSeq.albumIDs mutableCopy];
//	[currAlbumIDs removeObject:deletedAlbumID];
//	return [self saveAlbumSeq:[currAlbumIDs copy]];
//}

- (BOOL)saveAlbum:(Album *)album {
	
	[self setThumbForAlbum:album];
	
	NSError* error;
	if ([album save: &error]) {
		[self notifyChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"已加入\"%@\"", album.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (void)setThumbForAlbum:(Album *)album {
	if(!album.getThumb) {
		ArticleEntity *firstClip = album.clips[0];
		if(firstClip){
			[album setThumb:[self getThumb:firstClip.url]];
		}
	}
}

- (UIImage *)getThumb:(NSString *)url{
	return [[YYImageCache sharedCache] getImageForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:url]]];
}

- (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title {
	[[[UIAlertView alloc] initWithTitle:title
								message:text
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil] show];
}

-(BOOL)hasNetwork {	
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];

	if (networkStatus == NotReachable) {
		return NO;
	}
	return YES;
}

#pragma mark - For test
- (void)getAllDocument {
	CBLQuery* query = [_database createAllDocumentsQuery];
	query.allDocsMode = kCBLAllDocs;
	NSError *error;
	CBLQueryEnumerator* result = [query run: &error];
	for (CBLQueryRow* row in result) {
		CBLDocument *doc = row.document;
		NSString *isFromLocal = [doc propertyForKey:@"isFromLocal"];
		NSLog(@"isFromLocal = %@",isFromLocal);
	}
}
@end
