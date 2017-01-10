//
//  ClipController.m
//
//  Created by Lee Xing.
//

#import "ClipController.h"
#import "ClipPlayController.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "MyLBAdapter.h"
#import "EBCommentsViewController.h"
#import "ModelComment.h"
#import "ClipCell.h"
#import "ArticleEntity.h"
#import "MyLBService.h"
#import "AlbumAddClipDescViewController.h"
#import "AlbumSelectBottomSheetViewController.h"
#import "AlbumInfoViewController.h"
#import <STPopup/STPopup.h>
#import "CBLService.h"
#import <JDFPeekaboo/JDFPeekabooCoordinator.h>


#define cellMargin 10
//#define kCellHeight ceil((kScreenWidth) * 10.0 / 16.0)
#define screenWidth ((UIWindow *)[UIApplication sharedApplication].windows.firstObject).width
#define kScreenWidth ((UIWindow *)[UIApplication sharedApplication].windows.firstObject).width - cellMargin * 2
#define sHeight [UIScreen mainScreen].bounds.size.height
#define topBottomAdjust 10.0
#define tableViewYoffset -64.0
#define ratio16_9   (double)9/16
#define ratio4_3    (double)3/4
#define ratio16_10  (double)10/16
#define ratioSettings "ratioSettings"

@interface ClipController ()
@property (nonatomic, strong) STPopupController *popCtr;
@property CBLService *cblService;
@property Album *albumToAdd;
@property NSInteger indexOfSelectedClip;
@property clipActionType actionType;
@property NSString *clipCellID;
@property CGFloat correction;
@property NSDictionary *collectionList;
@property CGFloat cellHeight;
@property YYWebImageManager *backgroudManager;
@property YYWebImageManager *defaultManage;
@property NSInteger currIndex;
@property BOOL isScrollingDown;
@property BOOL hasWifi;
@property (nonatomic, strong) JDFPeekabooCoordinator *scrollCoordinator;
@property (nonatomic, weak) UISearchBar *searchBar;
@property NSString *searchKeywords;
@property BOOL playStopped;
@property UITableView *tableView;
//@property TLYShyNavBarManager *shyNavBarManager;
//@property NSArray *filteredClips;
//@property BOOL didAppear;
//@property NSInteger currMinIndex;
//@property NSOperationQueue *queue;
//@property (nonatomic, copy) NSString *clipToAdd;
//@property BOOL isAddAll;
@end

@implementation ClipController {
	NSMutableArray *data;
	MyLBService *lbService;
	NSDictionary* commentList;
//	NSString *shareText;
}

#pragma mark - View event
- (void)viewDidLoad {
	[super viewDidLoad];
	
	lbService = [MyLBService sharedManager];
	_cblService = [CBLService sharedManager];
	
	_currIndex = 0;
	_correction = 0;
	
	[self setupDownload];
	
	[self setUpCollectionList];
	
	[self setClipRatio:[self getRatioSetting]];
	
	[self setupTableView];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.view.backgroundColor = [UIColor whiteColor];
	self.navigationController.navigationBar.tintColor = [UIColor blackColor];
	
	[self setTitle: _header];
	
	self.tableView.fd_debugLogEnabled = NO;
	
	[self registerReusableCell];
	
	[self setUpScrollCoordinator];
	
	[self addInfoIcon];
	
	if(_showInfo) {
		[self showPopup];
	}
	
	[self initData];
	
	[self initHeader];
	
	[self.tableView reloadData];
}

- (void)setupTableView {
	CGRect tableViewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
	[self.view addSubview:self.tableView];
	[self.tableView setDelegate:self];
	[self.tableView setDataSource:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];	
	if(_playStopped) {
		[self autoPlayFullyVisibleImages];
	}else{
		[self fetchPostComments:NO];
	}	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if(_articleDicts) {
		if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
			// back button was pressed.  We know this is true because self is no longer
			// in the navigation stack.
//			[self.navigationController setNavigationBarHidden:YES];
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.scrollCoordinator disable];
	if(![self isVisible]){
		[self stopPlayingAllImages];
		if(![self presentedViewController]){
			[_backgroudManager.queue cancelAllOperations];
			[_defaultManage.queue cancelAllOperations];
			[[YYImageCache sharedCache].memoryCache removeAllObjects];
		}
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.scrollCoordinator enable];
}

- (BOOL)hidesBottomBarWhenPushed {
	return YES;
}

#pragma mark - Search
- (void)showSearchbar {
	CGRect myFrame = CGRectMake(0, 20, screenWidth, 44.0f);
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:myFrame];
	
	searchBar.backgroundColor = [UIColor lightGrayColor];
	searchBar.barTintColor = [UIColor lightGrayColor];
	searchBar.delegate = self;
	searchBar.showsCancelButton = YES;
	searchBar.placeholder = @"搜索描述";
	searchBar.barStyle = UISearchBarStyleMinimal;
//	[self.view addSubview:self.searchBar];
//	[self.tableView.tableHeaderView addSubview:self.searchBar];
//	self.navigationItem.titleView = self.searchBar;
	[self.navigationController.view insertSubview:searchBar aboveSubview:self.navigationController.navigationBar];
	
	_searchBar = searchBar;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[_searchBar resignFirstResponder];
	[self filterWithKeywords:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self cancelSearch];
	[_searchBar removeFromSuperview];
}

- (void)filterWithKeywords:(NSString *)keywords {
	_searchKeywords = keywords;
	[self refreshScreen:YES];
}

- (void)cancelSearch {
	_searchKeywords = nil;
	[self refreshScreen:YES];
}

#pragma mark - Download
- (void)setupDownload {
	_defaultManage = [YYWebImageManager sharedManager];
	YYImageCache *cache = [YYImageCache sharedCache];
	NSOperationQueue *queue = [NSOperationQueue new];
	queue.maxConcurrentOperationCount = 1;
	_backgroudManager = [[YYWebImageManager alloc] initWithCache:cache queue:queue];
	
	[self checkWifiConnection];
	[self setDownloadLimit:YES];
	
	[self observeChanges];
}

- (void)checkWifiConnection {
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	if (networkStatus == ReachableViaWiFi) {
		_hasWifi = YES;
	}else{
		_hasWifi = NO;
	}
}

-(void)setDownloadLimit:(BOOL)hasLimit {
	if(hasLimit) {
		_defaultManage.queue.maxConcurrentOperationCount = 1;
	}else{
		_defaultManage.queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
	}
}

- (void)observeChanges {
	[_defaultManage.queue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(checkNetworkStatus:)
	 name:kReachabilityChangedNotification
	 object:nil];
}

- (void)checkNetworkStatus:(NSNotification*)note{
	[self checkWifiConnection];
}

- (void)dealloc {
	[_defaultManage.queue removeObserver:self forKeyPath:@"operationCount"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
					   context:(void *)context {
	[self performBackgroundDownload:NO];
}

- (void)performBackgroundDownload:(BOOL)shouldStopCurrentBackgroundDownload{
	if(_defaultManage.queue.operationCount > 0) {
		[_backgroudManager.queue cancelAllOperations];
	}else {
		if(shouldStopCurrentBackgroundDownload) {
			[_backgroudManager.queue cancelAllOperations];
		}
		if(_hasWifi) {
			[self backgroudFetchImagesFromRow:_currIndex withDirection:_isScrollingDown];
		}
	}
}

- (void)backgroudFetchImagesFromRow:(NSInteger)row withDirection:(BOOL)scrollingDown{
	
	if(scrollingDown) {
		for (int i = (int)row + 1; i < [data count]; i++) {
			ArticleEntity *entity = (ArticleEntity *)data[i];
			if([entity.url length] != 0) {
				NSURL *url = [NSURL URLWithString:entity.url];
				BOOL cached = [[YYImageCache sharedCache] containsImageForKey:[url absoluteString]];
				if(!cached){
					[_backgroudManager requestImageWithURL:url
												   options:YYWebImageOptionShowNetworkActivity
												  progress:nil
												 transform:nil
												completion:nil];
				}
			}
		}
	}else {
		for (int i = (int)row - 1; i >= 0; i--) {
			ArticleEntity *entity = (ArticleEntity *)data[i];
			if([entity.url length] != 0) {
				NSURL *url = [NSURL URLWithString:entity.url];
				BOOL cached = [[YYImageCache sharedCache] containsImageForKey:[url absoluteString]];
				if(!cached){
					[_backgroudManager requestImageWithURL:url
												   options:YYWebImageOptionShowNetworkActivity
												  progress:nil
												 transform:nil
												completion:nil];
				}
			}
		}
	}
}

- (void)recordCurrIndex:(NSInteger)row {
	
	BOOL currScrollingDown;
	
	if(row > _currIndex) {
		currScrollingDown = YES;
	}else {
		currScrollingDown = NO;
	}
	
	_currIndex = row;
	
	if(currScrollingDown != _isScrollingDown) {
		_isScrollingDown = currScrollingDown;
		[self performBackgroundDownload:YES];
	}else{
		_isScrollingDown = currScrollingDown;
	}
}

- (void)helloFromCell:(UITableViewCell *)cell {
	NSInteger row = [self.tableView indexPathForCell:cell].row;
	NSLog(@"get image from cell = %ld", row);
}

#pragma mark - Initialization
- (void)setUpScrollCoordinator {
	self.scrollCoordinator = [[JDFPeekabooCoordinator alloc] init];
	self.scrollCoordinator.scrollView = self.tableView;
	self.scrollCoordinator.topView = self.navigationController.navigationBar;
}

-(void)registerReusableCell {
	
	[self.tableView registerClass:[TitleCell class] forCellReuseIdentifier:TitleCellIdentifier];
	
	_clipCellID = [self isInAlbum]? AlbumCellIdentifier: ClipCellIdentifier;
	
	[self.tableView registerClass:[ClipCell class] forCellReuseIdentifier:_clipCellID];
}

- (void)initData {
	NSMutableArray *entities = @[].mutableCopy;
	if(_searchKeywords) {
		[self converAlbumClips:_album.clips toData:entities withSearch:_searchKeywords];
	}else if (_news) {
		[self converAlbumClips:_news.image toData:entities withSearch:nil];
	}else if(_album) {
		[self converAlbumClips:_album.clips toData:entities withSearch:nil];
	}else if(_articleDicts) {
		[_articleDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSString *desc = obj[@"desc"];
			NSString *url = obj[@"url"];
			if(desc && [desc length] != 0) {
				[entities addObject:[[ArticleEntity alloc] initWithData:@"" desc:desc]];
			}
			[entities addObject:[[ArticleEntity alloc] initWithData:url desc:@""]];
		}];
	}else if(_articleURLs) {
		for (NSString *url in _articleURLs) {
			[entities addObject:[[ArticleEntity alloc] initWithData:url desc: @""]];
		}
	}
	
	data = [entities mutableCopy];
}

- (void)converAlbumClips:(NSArray *)clips toData:(NSMutableArray *)entities withSearch:(NSString *)keywords{
	NSMutableArray *pureURL = @[].mutableCopy;
	[clips enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ArticleEntity *entity = (ArticleEntity *)obj;
		if(!keywords || [entity.desc rangeOfString:_searchKeywords options:NSCaseInsensitiveSearch].location != NSNotFound)
		{
			NSString *desc = entity.desc;
			NSString *url = entity.url;
			if(desc && [desc length] != 0) {
				[entities addObject:[[ArticleEntity alloc] initWithData:@"" desc:desc]];
			}
			[entities addObject:[[ArticleEntity alloc] initWithData:url desc:@"" tag:idx]];
			[pureURL addObject:url];
		}
	}];
	_articleURLs = [pureURL copy];
}

- (void)initHeader {
	
	UIView *header = [UIView new];
	
	if(_summary && [_summary length] != 0)  {

		TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.frame = CGRectMake(cellMargin, 15, kScreenWidth, 60);
		
		label.textAlignment = NSTextAlignmentLeft;
		label.numberOfLines = 0;
		
		NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
		style.lineSpacing = 13;
		
		NSAttributedString *attString = [[NSAttributedString alloc] initWithString:_summary
																		attributes:@{
																					 NSFontAttributeName : [UIFont boldSystemFontOfSize:16],
																					 (id)kCTParagraphStyleAttributeName : style,
																					 }];
		
		label.text = attString;
		
		[label sizeToFit];
		
		[header addSubview:label];
		
		UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, label.bottom + cellMargin, self.view.width, 0.5)];
		lineView.backgroundColor = [UIColor lightGrayColor];
		[header addSubview:lineView];
		
		header.size = CGSizeMake(self.view.width, lineView.bottom + cellMargin);
		
	}else {
		header.size = CGSizeMake(self.view.width, cellMargin);
	}
	
	UIView *footer = [UIView new];
	footer.size = CGSizeMake(self.view.width, 0);
	
	[self.tableView setTableHeaderView:header];
	[self.tableView setTableFooterView:footer];
}

- (void)addInfoIcon {
	UIBarButtonItem *button;
	if(_fetchMode) {
		button = [[UIBarButtonItem alloc] initWithTitle:@"收藏全部" style:UIBarButtonItemStyleBordered target:self action:@selector(prepareToSaveAll)];
	}else if([self isInAlbum]) {
		button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showOverallActionsheet)];
	}else {
		button = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStyleBordered target:self action:@selector(showRatioActionsheet)];
	}
//	button.tintColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	self.navigationItem.rightBarButtonItem = button;
}

- (BOOL)isVisible {
	return [self isViewLoaded] && self.view.window;
}

#pragma mark - (User Interaction)
- (void)showPopup {
	
	NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	paragraphStyle.alignment = NSTextAlignmentCenter;
	
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"操作说明" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle}];
	
	NSAttributedString *lineOne= [[NSAttributedString alloc] initWithString:@"点击图片进入滑屏慢放模式" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0], NSParagraphStyleAttributeName : paragraphStyle}];
	
	NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString:@"点击播放/暂停，滑屏拖动播放" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSParagraphStyleAttributeName : paragraphStyle}];
	
	CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
	[button setTitle:@"知道了" forState:UIControlStateNormal];
	button.backgroundColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	button.layer.cornerRadius = 4;
	
	UILabel *titleLabel = [[UILabel alloc] init];
	titleLabel.numberOfLines = 0;
	titleLabel.attributedText = title;
	
	UILabel *lineOneLabel = [[UILabel alloc] init];
	lineOneLabel.numberOfLines = 0;
	lineOneLabel.attributedText = lineOne;
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tip"]];
	
	UILabel *lineTwoLabel = [[UILabel alloc] init];
	lineTwoLabel.numberOfLines = 0;
	lineTwoLabel.attributedText = lineTwo;
	
	CNPPopupController *popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, lineTwoLabel, imageView, button]];
	popupController.theme = [CNPPopupTheme defaultTheme];
	popupController.theme.popupStyle = CNPPopupStyleCentered;
	popupController.theme.cornerRadius = 10.0f;
	
	popupController.delegate = self;
	
	button.selectionHandler = ^(CNPPopupButton *button){
		[popupController dismissPopupControllerAnimated:YES];
	};
	
	[popupController presentPopupControllerAnimated:YES];
}

- (void)popupControllerDidDismiss:(CNPPopupController *)controller {
	if(!self.infoButton.selected) [self.infoButton select];
}

- (void)tappedButton:(DOFavoriteButton *)sender {
	[self showPopup];
}

#pragma mark - Public API
- (void)formActionForCell:(UITableViewCell *)cell withActionType:(clipActionType)type {
	_actionType = type;
	
	if(cell) {
		_indexOfSelectedClip = [self.tableView indexPathForCell:cell].row;
	}
	
	switch (type) {
		case addToAlbum:
			[self showBottomAlbumPopup];
			break;
		case addAllToAlbum:
			[self showBottomAlbumPopup];
			break;
		case editClip:
			[self showAlbumActionsheet];
			break;
		default:
			break;
	}
}

#pragma mark - (TableView Delegate)

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ArticleEntity *entity = data[indexPath.row];
	
	if([entity.url length] == 0) {
		TitleCell *cell = [tableView dequeueReusableCellWithIdentifier:TitleCellIdentifier];
		[self configureTitleCell:cell atIndexPath:indexPath isForHeight:false];
		return cell;
	}else {
		ClipCell *cell = [tableView dequeueReusableCellWithIdentifier:_clipCellID];
		[self configureCell:cell atIndexPath:indexPath isForHeight:false];
		return cell;
	}
}

- (void)configureCell:(ClipCell *)cell atIndexPath:(NSIndexPath *)indexPath isForHeight:(BOOL)isForHeight {
	cell.fd_enforceFrameLayout = YES; // Enable to use "-sizeThatFits:"
	cell.delegate = self;
	cell.cellHeight = _cellHeight;
	[cell setCellData: data[indexPath.row] isForHeight:isForHeight];
}

- (void)configureTitleCell:(TitleCell *)cell atIndexPath:(NSIndexPath *)indexPath isForHeight:(BOOL)isForHeight {
	cell.fd_enforceFrameLayout = YES; // Enable to use "-sizeThatFits:"
	[cell setCellData: data[indexPath.row] isForHeight:isForHeight];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	ArticleEntity *entity = data[indexPath.row];
	
	if([entity.url length] == 0) {
		return [tableView fd_heightForCellWithIdentifier:TitleCellIdentifier cacheByIndexPath:indexPath configuration:^(id cell) {
			[self configureTitleCell:cell atIndexPath:indexPath isForHeight:true];
		}];
	}else{
		return [tableView fd_heightForCellWithIdentifier:_clipCellID cacheByIndexPath:indexPath configuration:^(id cell) {
			[self configureCell:cell atIndexPath:indexPath isForHeight:true];
		}];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	CGFloat height = scrollView.frame.size.height;
	CGFloat contentYoffset = scrollView.contentOffset.y;
	CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
	
	if(contentYoffset <= tableViewYoffset + topBottomAdjust) {
		_correction = 100;
	}else if(distanceFromBottom <= height + topBottomAdjust) {
		_correction = -110;
	}else {
		_correction = 0;
	}
	
	[self autoPlayFullyVisibleImages];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[self recordCurrIndex:indexPath.row];
}

- (void)reload {
	[[YYImageCache sharedCache].memoryCache removeAllObjects];
	[[YYImageCache sharedCache].diskCache removeAllObjects];
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
}


#pragma mark - Clip Play

- (BOOL)isFullyVisible:(UITableViewCell *)cell {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

	CGRect rectOfCellInTableView = [self.tableView rectForRowAtIndexPath: indexPath];
	CGRect rectOfCellInSuperview = [self.tableView convertRect: rectOfCellInTableView toView: self.tableView.superview];
	
	return (rectOfCellInSuperview.origin.y <= sHeight - _cellHeight && rectOfCellInSuperview.origin.y >= 64);
}

- (BOOL)needToPlay:(UITableViewCell *)cell {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	CGRect rectOfCellInTableView = [self.tableView rectForRowAtIndexPath: indexPath];
	CGRect rectOfCellInSuperview = [self.tableView convertRect: rectOfCellInTableView toView: self.tableView.superview];
	
	CGFloat harfY = sHeight/2 - _correction;
	CGFloat topY = harfY - 5.005;
	CGFloat bottomY = harfY + 5.005;
	CGFloat cellTop = rectOfCellInSuperview.origin.y;
	CGFloat cellBottom = rectOfCellInSuperview.origin.y + _cellHeight;
	
	return (cellBottom > topY && cellTop < bottomY);
}

- (void)autoPlayFullyVisibleImages {
	_playStopped = NO;
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		if([cell isKindOfClass:[ClipCell class]]) {
			ClipCell *_cell = (ClipCell *) cell;
			if([self needToPlay: _cell]) {
				[_cell.webImageView startAnimating];
				[_cell setBorder];
			}else{
				[_cell.webImageView stopAnimating];
				[_cell unSetBorder];
			}
		}
	}
}

- (void)stopPlayingAllImages {
	_playStopped = YES;
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		if([cell isKindOfClass:[ClipCell class]]) {
			ClipCell *_cell = (ClipCell *) cell;
			if(_cell.webImageView.isAnimating) [_cell.webImageView stopAnimating];
		}
	}
}

- (void)recordSlowPlayWithUrl:(NSString *)url {
	[lbService recordSlowPlayWithClipID:url];
}

#pragma mark - Favorite
- (void)setFavoriate:(NSString *)url {
//	[[FavoriateMgr sharedInstance] setFavoriate:url];
//	[lbService recordFavoriteWithClipID:url postID:_postID];
	[_cblService setFavoriate:url];
}
- (void)unsetFavoriate:(NSString *)url {
//	[[FavoriateMgr sharedInstance] unsetFavoriate:url];
	[_cblService unsetFavoriate:url];
}
- (BOOL)isFavoriate:(NSString *)url {
//	return [[FavoriateMgr sharedInstance] isFavoriate:url];
	return [_cblService isFavoriate:url];
}

#pragma mark - Comments

- (void)fetchPostComments:(BOOL)isRefresh {
	
	NSString *id_post = [self postID];
	
	if(self.articleURLs.count > 0) {
		[lbService getCommentsSummaryByClipIDs:[_articleURLs copy] isRefresh:isRefresh success:^(NSArray *list) {
			[self generateCommentList:list];
		} failure:^{
		}];
	}else if(id_post){
		[lbService getCommentsSummaryByPostID:id_post isRefresh:isRefresh success:^(NSArray *list) {
			[self generateCommentList:list];
		} failure:^{
		}];
	}
}

- (void)generateCommentList:(NSArray *)comments {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
	
	for (NSDictionary *comment in comments) {
		[dict setObject:[comment objectForKey:@"comment_quantity"] forKey:[comment objectForKey:@"id_clip"]];
	}
	
	commentList = [dict copy];
	
	[self updateCellQty];
}

- (void)updateCellQty {
	
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		if([cell isKindOfClass:[ClipCell class]]) {
			ClipCell *_cell = (ClipCell *) cell;
			[_cell updateCommentQty];
		}
	}
}

- (NSString *)getCommentQty:(NSString *)clipID {
	if(commentList == nil) {
		return nil;
	}
	
	NSString *qty = [[commentList objectForKey:clipID] stringValue];
	return qty? qty: @"";
}

- (void)showComments:(NSString *)clipID {
	EBCommentsViewController *clipCtr = [[EBCommentsViewController alloc] init];
	[clipCtr setClipID:clipID];
	[clipCtr setDelegate:self];
	[self setDownloadLimit:NO];
	clipCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
	[self presentViewController:clipCtr animated:YES completion:nil];
}

- (void)closeCommentView {
	[self setDownloadLimit:YES];
}

#pragma mark - Share

- (void)shareClip:(NSURL *)clipID {
	[lbService shareWithClipID:clipID];
}

#pragma mark - Album & Favorite

- (void)showBottomAlbumPopup {
	STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName:@"favorite" bundle:nil] instantiateViewControllerWithIdentifier:@"addList"]];
	
	_popCtr = popupController;
	popupController.style = STPopupStyleBottomSheet;
	
	[popupController.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewDidTap)]];
	
	[STPopupNavigationBar appearance].tintColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	
	[popupController presentInViewController:self];
}

- (void)backgroundViewDidTap {
	[self.popCtr dismiss];
}

- (void)showNewAlbumForm {
	UIAlertView* alert= [[UIAlertView alloc] initWithTitle:@"新建收藏夹"
												   message:@"请输入名称:"
												  delegate:self
										 cancelButtonTitle:@"取消"
										 otherButtonTitles:@"确定", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alert show];
}

- (void)saveClipToAlbumWithDesc:(NSString *)desc {
	if([_cblService addClip:[self urlForSeletedClip] toAlum:_albumToAdd withDesc:desc]) {
		[self setCollected:[self urlForSeletedClip]];
		[((ClipCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_indexOfSelectedClip inSection:0]]) selectAlbumButton];
	}
	
//	if([_cblService addClip:[self urlForSeletedClip] toAlum:_albumToAdd withDesc:desc]) {
//		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"已加入\"%@\"", _albumToAdd.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
//	}else{
//		[JDStatusBarNotification showWithStatus:@"操作失败，请重试" dismissAfter:2.0 styleName:JDStatusBarStyleWarning];
//	}
}

- (NSString *)urlForSeletedClip {
	ArticleEntity *entity = data[_indexOfSelectedClip];
	return entity.url;
}

- (void)createNewAlbumWithTitle:(NSString *)title {
	Album *album = [_cblService creatAlubmWithTitle:title];
	if(album) {
		_albumToAdd = album;
		if(_actionType == addAllToAlbum) {
			[self saveAllClips];
		}else{
			[self showClipDescPopup:@""];
		}
	}
}

- (void)prepareToSaveAll{
	[self formActionForCell:nil withActionType:addAllToAlbum];
}

- (void)saveAllClips {
	[_cblService addClips:_articleURLs toAlum:_albumToAdd];
//	if([_cblService addClips:_articleURLs toAlum:_albumToAdd]){
//		[JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"已加入\"%@\"", _albumToAdd.title] dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
//	}
}

- (IBAction)unwindBack:(UIStoryboardSegue *)segue {

	UIViewController *source = [segue sourceViewController];
	
	if([source isKindOfClass:[AlbumAddClipDescViewController class]]){
		AlbumAddClipDescViewController *ctr = ((AlbumAddClipDescViewController *)source);
		if(ctr.shouldSave) {
			if(_actionType == addToAlbum) {
				[self saveClipToAlbumWithDesc:ctr.desc.text];
			}else if(_actionType == modifyDesc) {
				[self modifyClipDesc:ctr.desc.text];
			}
		}
	}else if([source isKindOfClass:[AlbumSelectBottomSheetViewController class]]) {
		AlbumSelectBottomSheetViewController *ctr = ((AlbumSelectBottomSheetViewController *)source);
		_albumToAdd = ctr.selectedAlbum;
		if(_actionType == addAllToAlbum) {
			if(_albumToAdd){
				[self saveAllClips];
			}else {
				[self showNewAlbumForm];
			}
		}else{
			if(_albumToAdd){
				[self showClipDescPopup:@""];
			}else {
				[self showNewAlbumForm];
			}
		}
	}else if([source isKindOfClass:[AlbumInfoViewController class]]) {
		AlbumInfoViewController *ctr = ((AlbumInfoViewController *)source);
		if(ctr.shouldSave) {
			[self updateAlbumInfoWithTitle:ctr.name withDesc:ctr.desc];
		}
	}
}

- (void)modifyClipDesc:(NSString *)newDesc {
	NSInteger clipIndexInAlbum = ((ArticleEntity *)data[_indexOfSelectedClip]).tag;
	NSString *origDesc = ((ArticleEntity *)_album.clips[clipIndexInAlbum]).desc;
	
	//No need to change if not changed
	if([origDesc isEqualToString:newDesc]) {
		return;
	}
	
	if([_cblService modifyClipDesc:newDesc withIndex:clipIndexInAlbum forAlbum:_album]) {
		[self refreshScreen:YES];
	}
}

- (void)deleteClip {
	NSInteger clipIndexInAlbum = ((ArticleEntity *)data[_indexOfSelectedClip]).tag;
	if([_cblService deleteClipWithIndex:clipIndexInAlbum forAlbum:_album]) {
		[self refreshScreen:YES];
	}
}

- (void)showClipDescPopup:(NSString *)desc {
	AlbumAddClipDescViewController *ctr = [[UIStoryboard storyboardWithName:@"favorite" bundle:nil] instantiateViewControllerWithIdentifier:@"addDesc"];
	
	[ctr setUrl:[self urlForSeletedClip]];
	ctr.currDesc = desc;
	ctr.modalPresentationStyle = UIModalPresentationCurrentContext;
	
	UINavigationController *navigationController =
	[[UINavigationController alloc] initWithRootViewController:ctr];
	navigationController.navigationBar.tintColor = [UIColor blackColor];
	
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)prepareForDescModify {
	NSString *curDesc = @"";
	if(_indexOfSelectedClip != 0) {
		ArticleEntity *entity = data[_indexOfSelectedClip - 1];
		curDesc = entity.desc;
	}
	
	[self showClipDescPopup:curDesc];
}

- (BOOL)isInAlbum {
	return _album? YES: NO;
}

- (void)performAlbumAction:(clipActionType)type{
	_actionType = type;
	switch (type) {
		case addToAlbum:
			[self showBottomAlbumPopup];
			break;
		case modifyDesc:
			[self prepareForDescModify];
			break;
		case deleteClip:
			[self deleteClip];
			break;
		default:
			break;
	}
}

-(void)prepareForAlbumInfo {
	
	AlbumInfoViewController *ctr = [[UIStoryboard storyboardWithName:@"favorite" bundle:nil] instantiateViewControllerWithIdentifier:@"albumInfo"];
	ctr.modalPresentationStyle = UIModalPresentationCurrentContext;
	ctr.name = _album.title;
	ctr.desc = _album.desc;
	
	UINavigationController *navigationController =
	[[UINavigationController alloc] initWithRootViewController:ctr];
	navigationController.navigationBar.tintColor = [UIColor blackColor];
	
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)updateAlbumInfoWithTitle:(NSString *)title withDesc:(NSString *)desc {
//	NSLog(@"from album info, title = %@, desc = %@", title, desc);
	if([_cblService updateAlbumInfo:title withDesc:desc forAlbum:_album]) {
		[self setTitle:title];
		[self setSummary:desc];
		[self initHeader];
		[self refreshScreen:YES];
	}
}

- (void)setUpCollectionList {
	_collectionList = [NSMutableDictionary new];
}

- (void)setCollected:(NSString *)url{
	[_collectionList setValue:@"YES" forKey:url];
}

- (BOOL)isCollected:(NSString *)url {	
	if([_collectionList objectForKey:url]) {
		return YES;
	}
	return NO;
}

#pragma mark - Action Sheet for album operation

- (void)showOverallActionsheet {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self
													cancelButtonTitle:@"取消"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"设置动图比例", @"根据描述过滤", @"修改收藏夹名称", nil];
	actionSheet.tag = 1;
	[actionSheet showInView:self.view];
}

- (void)showRatioActionsheet {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"设置动图比例"
															 delegate:self
													cancelButtonTitle:@"取消"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"4:3", @"16:10", @"16:9", nil];
	actionSheet.tag = 2;
	[actionSheet showInView:self.view];
}

- (void)showAlbumActionsheet {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"操作此动图"
															 delegate:self
													cancelButtonTitle:@"取消"
											   destructiveButtonTitle:@"删除动图"
													otherButtonTitles:@"修改描述", @"加入其他收藏夹", nil];
	actionSheet.tag = 3;
	[actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if(actionSheet.tag == 1) {
		switch (buttonIndex) {
			case 0:
				[self showRatioActionsheet];
				break;
			case 1:
				[self showSearchbar];
				break;
			case 2:
				[self prepareForAlbumInfo];
				break;
			default:
				break;
		}
	}else if (actionSheet.tag == 2){
		switch (buttonIndex) {
			case 0:
				[self changeClipRatio:ratio4_3];
				break;
			case 1:
				[self changeClipRatio:ratio16_10];
				break;
			case 2:
				[self changeClipRatio:ratio16_9];
				break;
			default:
				break;
		}
	}else if(actionSheet.tag == 3){
		clipActionType type = noAction;
		switch (buttonIndex) {
			case 0:
				type = deleteClip;
				break;
			case 1:
				type = modifyDesc;
				break;
			case 2:
				type = addToAlbum;
				break;
			default:
				break;
		}
		[self performAlbumAction:type];
	}
}

- (void)setClipWidth:(CGFloat)width withHeight:(CGFloat)height {
	[self setCellHeight:ceil((kScreenWidth) * height / width)];
}

- (void)setClipRatio:(double)ratio {
	[self setCellHeight:ceil((kScreenWidth) * ratio)];
}

- (void)changeClipRatioWithWidth:(CGFloat)width withHeight:(CGFloat)height {
	[self setClipWidth:width withHeight:height];
	[self refreshScreen:NO];
}

- (void)changeClipRatio:(double)ratio {
	[self setRatioSetting:ratio];
	[self setClipRatio:ratio];
	[self refreshScreen:NO];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex > 0) {
		NSString* title = [alert textFieldAtIndex:0].text;
		if (title.length > 0) {
			[self createNewAlbumWithTitle:title];
		}
	}
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
	UITextField *textField = [alertView textFieldAtIndex:0];
	if ([textField.text length] == 0){
		return NO;
	}
	return YES;
}

#pragma mark - Help

- (void)refreshScreen:(BOOL)reloadData{
	if(reloadData){
		[self initData];
	}
	[self.tableView reloadData];
	[self autoPlayFullyVisibleImages];
}

- (void)setRatioSetting:(double)ratio {
	NSUserDefaults *nud = [NSUserDefaults standardUserDefaults];
	[nud setObject:[NSNumber numberWithDouble:ratio] forKey:@ratioSettings];
	[nud synchronize];
}

- (double)getRatioSetting {
	NSUserDefaults *nud = [NSUserDefaults standardUserDefaults];
	NSNumber *ratio = [nud objectForKey:@ratioSettings];
	if(!ratio){
		return ratio4_3;
	}
	return [ratio doubleValue];
}

- (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end
