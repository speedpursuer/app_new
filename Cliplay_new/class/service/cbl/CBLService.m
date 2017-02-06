//
//  CBLService.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/23.
//
//

#import "CBLService.h"
#import "FCUUID.h"
#import "MRProgress.h"
#import "JDStatusBarNotification.h"
#import "Reachability.h"

#define didSyncedFlag @"didSynced"
#define kLocalFlag @"isFromLocal"
#define kDBName @"cliplay"
#define kStorageType kCBLForestDBStorage
#define kContentDBName @"cliplay_content"
#define kDBFileType @"cblite2"
//#define cbserverURL   @"http://localhost:4984/cliplay_user_data"
#define cbserverURL @"http://121.40.197.226:8000/cliplay_user_data"
#define cbContentServerURL @"http://121.40.197.226:8000/cliplay_prod_new"
//#define cbContentServerURL @"http://121.40.197.226:8000/cliplay_staging"
#define cbContentUserName  @"app_viewer"
#define cbContentPassword  @"Cliplay1234"
//#define kDidSynced @"didSynced"


@interface CBLService()
@property (nonatomic) CBLReplication *push;
@property (nonatomic) CBLReplication *pull;
@property (nonatomic) BOOL isSynced;
@property (nonatomic) NSError *lastSyncError;
@property MRProgressOverlayView *progressView;
@property NSString *uuid;
@property NSDictionary *moves;
@property BOOL isSyncing;
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
	[self loadContent];
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
		}else {
			database = [[CBLManager sharedInstance] openDatabaseNamed:publicDBName
														  withOptions:option
																error:&error];
		}
	}
	
	_contentDatabase = database;
}

- (void)loadContent {
	[self loadNews];
	[self loadMoves];
	[self indexedPlayers];
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
	[self notifyAlbumChanges];
}

- (void)notifyAlbumChanges {
	[[NSNotificationCenter defaultCenter] postNotificationName:kAlbumListChange object:nil];
}

#pragma mark - Content (News & move)

- (Post *)clipsForPlayer:(Player*) player withMove:(Move *)move {
	NSString *postID = [NSString stringWithFormat:@"post_%@_%@", player.docID, move.docID];		
	Post *post = [Post modelForDocument:[self contentDocumentWithDocID:postID]];
	return post;
}

- (NSArray *)newsForPlayer:(Player*) player {
	if(!player.news) {
		return nil;
	}
	CBLQuery* query = [self queryAllContent];
	query.keys = player.news;
	query.descending = YES;
	
	NSError *error;
	NSMutableArray *allNews = [NSMutableArray new];
	CBLQueryEnumerator* result = [query run: &error];
	for (CBLQueryRow* row in result) {
		[allNews addObject:[News modelForDocument:row.document]];
	}
	return [allNews copy];
}

- (NSArray *)movesForPlayer:(Player *)player {
	NSMutableArray *list = [NSMutableArray new];
	NSDictionary* clip_moves = [player getValueOfProperty:@"clip_moves"];
	NSDictionary *moveCopy = [_moves copy];
	for(NSString *moveName in [clip_moves allKeys]) {
		NSInteger clipCount = [[clip_moves valueForKey:moveName] integerValue];
		if(clipCount > 0) {
			Move *move = [moveCopy objectForKey:moveName];
			move.count = clipCount;
			[list addObject:move];
		}
	}
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"count"
																   ascending:NO];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	return [[list copy] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)loadMoves {
	CBLQuery* query = [self queryAllContent];
	query.startKey = @"move_";
	query.endKey   = @"move_\uffff";
	
	NSError *error;
	NSMutableDictionary *dict = [NSMutableDictionary new];
	NSString *languageID = [[NSBundle mainBundle] preferredLocalizations].firstObject;
	CBLQueryEnumerator* result = [query run: &error];
	for (CBLQueryRow* row in result) {
		Move *move = [Move modelForDocument:row.document];
		[self configMove:move byLangID:languageID];
		[dict setObject:move forKey:row.document.documentID];
	}
	_moves = [dict copy];
}

- (void)configMove:(Move *)move byLangID:(NSString *)lang{
	if(![lang hasPrefix:@"zh"]) {
		move.move_name = move.move_name_en;
		move.desc = move.desc_en;
	}
}

- (void)loadNews {
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
	_news = [allNews copy];
}

- (CBLQuery *)queryAllContent {
	CBLQuery* query = [self.contentDatabase createAllDocumentsQuery];
	return query;
}

- (CBLDocument *)contentDocumentWithDocID:(NSString *)docID {
	return self.contentDatabase[docID];
}

- (void)indexedPlayers {
	NSMutableArray *players = [NSMutableArray new];
	
	NSArray *list = [self allPlayers];
	
	UILocalizedIndexedCollation *theCollation = [UILocalizedIndexedCollation currentCollation];
	
	for (Player *player in list) {
		NSInteger sect = [theCollation sectionForObject:player collationStringSelector:@selector(lastName)];
		player.sectionNumber = sect;
	}
	
	NSInteger highSection = [[theCollation sectionTitles] count];
	NSMutableArray *sectionArrays = [NSMutableArray arrayWithCapacity:highSection];
	for (int i = 0; i < highSection; i++) {
		NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:1];
		[sectionArrays addObject:sectionArray];
	}
	
	for (Player *player in list) {
		[(NSMutableArray *)[sectionArrays objectAtIndex:player.sectionNumber] addObject:player];
	}
	
	for (NSMutableArray *sectionArray in sectionArrays) {
		NSArray *sortedSection = [theCollation sortedArrayFromArray:sectionArray
											collationStringSelector:@selector(lastName)];
		[players addObject:sortedSection];
	}
	_players = [players copy];
}

- (NSArray *)allPlayers {
	CBLQuery* query = [self queryAllContent];
	query.startKey = @"player_";
	query.endKey   = @"player_\uffff";
	
	NSError *error;
	NSMutableArray *allPlayers = [NSMutableArray new];
	CBLQueryEnumerator* result = [query run: &error];
	NSString *languageID = [[NSBundle mainBundle] preferredLocalizations].firstObject;
	for (CBLQueryRow* row in result) {
		NSInteger total = [[row.document propertyForKey:@"clip_total"] integerValue];
		if(total > 2) {
			Player *player = [Player modelForDocument:row.document];
			[self configPlayer:player byLangID:languageID];
			[allPlayers addObject:player];
		}
	}
	return [allPlayers copy];
}

- (void)configPlayer:(Player *)player byLangID:(NSString *)lang{
	if([lang hasPrefix:@"zh"]) {
		NSArray *fullName = [player.name componentsSeparatedByString: @"·"];
		player.lastName = fullName.count == 2? [fullName objectAtIndex: 1]: player.name;
	}else{
		player.name = player.name_en;
		player.lastName = player.name_en;
	}
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

- (void)notifyContentUpdate {
	[self loadContent];
	[[NSNotificationCenter defaultCenter] postNotificationName:kContentUpdate object:nil];
}

#pragma mark - Album

- (Album*)creatAlubmWithTitle:(NSString*)title {
	Album* album = [Album getAlbumInDatabase:_database withTitle:title withUUID:_uuid];
	NSError *error;
	if ([album save:&error]) {
		[_albumSeq addAlbumID:[album docID]];
		[self notifyAlbumChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"New Collection \"%@\" created", @"cblservice"), album.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return album;
	}else {
		[self showError];
//		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Request failed, please retry", @"cblservice") dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return nil;
	}
}

- (BOOL)deleteAlbum:(Album *)album {
	NSError *error;
	NSString *albumName = album.title;
	NSString *albumID = [album docID];
	if ([album deleteDocument:&error]){
		[_albumSeq deleteAlbumID:albumID];
		[self notifyAlbumChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Collection \"%@\" removed", @"cblservice"), albumName] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else{
		[self showError];
//		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Request failed, please retry", @"cblservice") dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (BOOL)addClip:(NSString *)url toAlum:(Album *)album withDesc:(NSString *)desc {
	
	NSMutableArray *existingClips = [NSMutableArray arrayWithArray:album.clips];
	ImageEntity *clip = [[ImageEntity alloc] initWithData:url desc:desc];
	
	[existingClips addObject:clip];
	album.clips = [existingClips copy];
	
	return [self saveAlbum:album];
}

- (BOOL)addClips:(NSArray *)urls toAlum:(Album *)album{
	
	NSMutableArray *existingClips = [NSMutableArray arrayWithArray:album.clips];
	
	for(NSString *url in urls) {
		ImageEntity *clip = [[ImageEntity alloc] initWithData:url desc:@""];
		[existingClips addObject:clip];
	}
	
	album.clips = [existingClips copy];
	
	return [self saveAlbum:album];
}

- (BOOL)modifyClipDesc:(NSString *)newDesc withIndex:(NSInteger)index forAlbum:(Album *)album {
	
	NSMutableArray *clipsToModify = [album.clips mutableCopy];
	ImageEntity *clip = clipsToModify[index];
	ImageEntity *newClip = [[ImageEntity alloc] initWithCopy:clip];
	newClip.desc = newDesc;
	[clipsToModify replaceObjectAtIndex:index withObject:newClip];
	album.clips = [clipsToModify copy];
	
	NSError* error;
	if ([album save: &error]) {
		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Comment Changed", @"cblservice") dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[self showError];
//		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Request failed, please retry", @"cblservice") dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
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
		ImageEntity *currFirstClip = clipsToModify[0];
		[album setThumb:[self getThumb:currFirstClip.url]];
	}
	album.clips = [clipsToModify copy];
	
	NSError* error;
	if ([album save: &error]) {
		[self notifyAlbumChanges];
		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Clip Removed", @"cblservice") dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[self showError];
//		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
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
		[self notifyAlbumChanges];
		[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Collection Info Saved", @"cblservice") dismissAfter:1.2 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[self showError];
//		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
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
//	_uuid = @"cd196ad39362410c81490f9a6545f766";
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

- (void)syncStartWithDelegate:(NewsTableViewController *)delegate {
	_delegate = delegate;
	[self syncContentDBFromRemote];
}

- (void)syncContentDBFromRemote {
	
	if(_isSyncing) return;
	
	_isSyncing = YES;
	
	NSURL *syncUrl = [NSURL URLWithString:cbContentServerURL];
	
	_pull = [_contentDatabase createPullReplication:syncUrl];
	
	id<CBLAuthenticator> auth;
	auth = [CBLAuthenticator basicAuthenticatorWithName: cbContentUserName
											   password: cbContentPassword];
	_pull.authenticator = auth;
	
	NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
	[nctr addObserver:self selector:@selector(contentReplicationProgress:)
				 name:kCBLReplicationChangeNotification object:_pull];
	
	_lastSyncError = nil;
	
	[_pull start];
}

- (void)contentReplicationProgress:(NSNotification *)notification {
	NSError* error = _pull.lastError;
	if(error){
		_lastSyncError = error;
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
			[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sync Failed, please check network", @"cblservice") dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		}else if(_pull.changesCount == _pull.completedChangesCount) {
			if(_pull.completedChangesCount > 0) {
				[self notifyContentUpdate];
			}
		}
		_isSyncing = NO;
		[_delegate syncEnd];
	}
}

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
	
	__weak typeof(self) _self = self;
	[Helper performBlock:^{
		[_self.pull start];
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
			[JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sync of history failed, please check network", @"cblservice") dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		}else if(_pull.changesCount == _pull.completedChangesCount) {
			// Successfull pull means - 1. No error 2. all changes completed
			[_progressView setProgress:1.0];
			
			//Resolve conflict and mark pull complete
			if([self processConflict]) {
				[self updateAlbumSeq];
				[self setDidSynced];
			};
		}
		
		__weak typeof(self) _self = self;
		[Helper performBlock:^{
			[_self.progressView dismiss:NO];
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
	[self notifyAlbumChanges];
}

//- (BOOL)didSyced {
//	return _isSynced;
//}

- (void)showProgress {
	
	MRProgressOverlayView *view = [MRProgressOverlayView showOverlayAddedTo:[UIApplication sharedApplication].keyWindow animated:NO];
	
	view.mode = MRProgressOverlayViewModeDeterminateHorizontalBar;
	
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Syncing history data", @"Progress of Syncing history data") attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
	
	view.titleLabelAttributedText = title;
	
	view.tintColor = CLIPLAY_COLOR;
	
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
		[self notifyAlbumChanges];
		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Saved to Collection \"%@\"", @"cblservice"), album.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
		return YES;
	}else {
		[self showError];
//		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
		return NO;
	}
}

- (void)setThumbForAlbum:(Album *)album {
	if(!album.getThumb) {
		ImageEntity *firstClip = album.clips[0];
		if(firstClip){
			[album setThumb:[self getThumb:firstClip.url]];
		}
	}
}

- (UIImage *)getThumb:(NSString *)url{
	return [[CacheManager sharedManager] cachedGIFWith:url];
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

- (void)fetchNewsByID:(NSString *)newID completionHandlder:(void (^)(id<Content> content))handlder {
	NSString *authStr = [NSString stringWithFormat:@"%@:%@", cbContentUserName, cbContentPassword];
	NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
	NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
	
	
	NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/", cbContentServerURL] stringByAppendingString: newID]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setValue:authValue forHTTPHeaderField:@"Authorization"];
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response,
											   NSData *data, NSError *connectionError) {
		 if (data.length > 0 && connectionError == nil) {
			 NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
																  options:0
																	error:NULL];
			 
			 PushFeed *feed = [PushFeed new];
			 NSMutableArray *array = [NSMutableArray new];
			 
			 [dict[@"image"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				 ImageEntity *entry = [[ImageEntity alloc] initWithJSON:obj];
				 [array addObject:entry];
			 }];
			 
			 feed.image = [array copy];
			 feed.summary = dict[@"summary"];
			 
			 handlder(feed);
		 }
	}];
}

- (void)showErrorWithMessage:(NSString *)msg {
	[JDStatusBarNotification showWithStatus:msg dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
}

- (void)showError{
	[self showErrorWithMessage:NSLocalizedString(@"Request failed, please retry", @"cblservice")];
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

- (void)getSpecificContent{
	NSString *docID = @"player_kobe_bryant";
	CBLDocument* document = [self contentDocumentWithDocID:docID];
	NSLog(@"data = %@", [document propertyForKey:@"player_image"]);
}

@end
