
//
//  ClipController.m
//
//  Created by Lee Xing.
//

#import "ClipController.h"
#import "ClipPlayController.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "AppDelegate.h"
#import "EBCommentsViewController.h"
#import "ModelComment.h"
#import "ClipCell.h"
#import "AlbumAddClipDescViewController.h"
#import "AlbumSelectBottomSheetViewController.h"
#import "AlbumInfoViewController.h"
#import <STPopup/STPopup.h>
#import <TLYShyNavBar/TLYShyNavBarManager.h>
#import "DismissAnimation.h"
#import "PresentedAnimation.h"
#import "SwipeUpInteractiveTransition.h"
#import "AutoRotateNavController.h"


#define cellMargin 10
//#define kCellHeight ceil((kScreenWidth) * 10.0 / 16.0)
#define screenWidth ((UIWindow *)[UIApplication sharedApplication].windows.firstObject).width
#define kScreenWidth ((UIWindow *)[UIApplication sharedApplication].windows.firstObject).width - cellMargin * 2
#define sHeight [UIScreen mainScreen].bounds.size.height
#define topBottomAdjust 10.0
#define tableViewYoffset -64.0

@interface ClipController ()
//Control
@property clipActionType actionType;
@property NSString *clipCellType;
@property CGFloat correction;
@property CGFloat cellHeight;
@property BOOL isScrollingDown;
@property BOOL playStopped;
@property BOOL isDismissed;
//Data
@property NSArray *data;
@property Album *albumToAdd;
@property NSDictionary* commentList;
@property NSString *searchKeywords;
@property NSDictionary *collectionList;
@property NSInteger indexOfSelectedClip;
@property NSInteger currIndexForDownload;
//UI
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) STPopupController *popCtr;
@property (nonatomic, strong) SwipeUpInteractiveTransition *interactiveTransition;
//Service
@property (nonatomic, weak) CacheManager *cacheManager;
@property (nonatomic, weak) CBLService *cblService;
@property (nonatomic, weak) LBService *lbService;

//@property (nonatomic, strong) JDFPeekabooCoordinator *scrollCoordinator;
//@property BOOL hasWifi;
//@property (nonatomic, strong) YYWebImageManager *backgroudManager;
//@property (nonatomic, weak) YYWebImageManager *defaultManage;
//@property TLYShyNavBarManager *shyNavBarManager;
//@property NSArray *filteredClips;
//@property BOOL didAppear;
//@property NSInteger currMinIndex;
//@property NSOperationQueue *queue;
//@property (nonatomic, copy) NSString *clipToAdd;
//@property BOOL isAddAll;
@end

@implementation ClipController {
//	MyLBService *lbService;
//	NSDictionary* commentList;
//	NSString *shareText;
}

#pragma mark - View event
- (void)viewDidLoad {
	[super viewDidLoad];
	
	_lbService = [LBService sharedManager];
	_cblService = [CBLService sharedManager];
	
	[self initValues];
	
//	[self setupDownload];
	
	[self setUpCollectionList];
	
	[self setClipRatio:[self getRatioSetting]];
	
	[self setupTableView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	[self setTitle: _header];
	
	self.tableView.fd_debugLogEnabled = NO;
	
	[self registerReusableCell];
	
	[self setupNavBarStyle];
	
	[self setupNavItem];
	
	[self initData];
	
	[self initHeader];
	
	[self.tableView reloadData];
}

- (void)initValues {
	_currIndexForDownload = 0;
	_correction = 0;
	_isScrollingDown = YES;
}

- (void)setupNavBarStyle {
	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:nil];
}

- (void)setupTableView {
	CGRect tableViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
	
	UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
	[self.view addSubview:tableView];
	self.tableView = tableView;
	[self.tableView setDelegate:self];
	[self.tableView setDataSource:self];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self setupNavAutoHide];
}

- (void)setupNavAutoHide {
	UIView *view = view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 1.f)];
	view.backgroundColor = [UIColor clearColor];
	[self.shyNavBarManager setExtensionView:view];
	self.tableView.contentInset = UIEdgeInsetsMake(64,0,0,0);
	self.shyNavBarManager.scrollView = self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupDownload];
//	[UIViewController attemptRotationToDeviceOrientation];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if(_playStopped) {
		[self autoPlayFullyVisibleImages];
	}else{
		[self fetchPostComments:NO];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if(![self isVisible]){
		[self stopPlayingAllImages];
		if(![self presentedViewController]){
			_isDismissed = YES;
			self.shyNavBarManager.scrollView = nil;
			self.shyNavBarManager.extensionView = nil;
		}
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	NSLog(@"didReceiveMemoryWarning!!!!!");
}

- (void)dealloc {
	[_cacheManager stopGIFAllOprts];
}

- (BOOL)hidesBottomBarWhenPushed {
	return YES;
}

#pragma mark - Search
- (void)showSearchbar {
	CGRect myFrame = CGRectMake(0, 20, screenWidth, 44.0f);
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:myFrame];
	
	searchBar.backgroundColor = CLIPLAY_COLOR;
	searchBar.barTintColor = CLIPLAY_COLOR;
	searchBar.delegate = self;
	searchBar.showsCancelButton = YES;
	searchBar.placeholder = @"搜索描述";
	searchBar.barStyle = UISearchBarStyleMinimal;
//	[self.view addSubview:self.searchBar];
//	[self.tableView.tableHeaderView addSubview:self.searchBar];
//	self.navigationItem.titleView = self.searchBar;
	[self.navigationController.view insertSubview:searchBar aboveSubview:self.navigationController.navigationBar];
	
	[searchBar becomeFirstResponder];
	
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
	_cacheManager = [CacheManager sharedManager];
	if(_cacheManager.delegate != self) {
		_cacheManager.delegate = self;
	}
}

- (void)handleBackgroundDownload {
	if(_isDismissed) return;
	if(_isScrollingDown) {
		for (int i = (int)_currIndexForDownload + 1; i < [_data count]; i++) {
			ImageEntity *entity = (ImageEntity *)_data[i];
			if([entity.url length] != 0) {
				[self.cacheManager requestGIFWithURL:entity.url];
			}
		}
	}else {
		for (int i = (int)_currIndexForDownload - 1; i >= 0; i--) {
			ImageEntity *entity = (ImageEntity *)_data[i];
			if([entity.url length] != 0) {
				[self.cacheManager requestGIFWithURL:entity.url];
			}
		}
	}
}

- (void)recordCurrIndex:(NSInteger)row {
	
	BOOL currScrollingDown;
	
	if(row >= _currIndexForDownload) {
		currScrollingDown = YES;
	}else {
		currScrollingDown = NO;
	}
	
	_currIndexForDownload = row;
	
	if(currScrollingDown != _isScrollingDown) {
		_isScrollingDown = currScrollingDown;
		[_cacheManager performBackgroundDownload];
	}else{
		_isScrollingDown = currScrollingDown;
	}
}

- (void)helloFromCell:(UITableViewCell *)cell {
	NSInteger row = [self.tableView indexPathForCell:cell].row;
	NSLog(@"get image from cell = %ld", row);
}

#pragma mark - Initialization

-(void)registerReusableCell {
	
	[self.tableView registerClass:[TitleCell class] forCellReuseIdentifier:TitleCellIdentifier];
	
	_clipCellType = [self isInAlbum]? AlbumCellIdentifier: ClipCellIdentifier;
	
	[self.tableView registerClass:[ClipCell class] forCellReuseIdentifier:_clipCellType];
}

- (void)initData {
	NSMutableArray *entities = @[].mutableCopy;
	if(_searchKeywords) {
		[self converAlbumClips:_album.clips toData:entities withSearch:_searchKeywords];
	}else if (_content) {
		[self converAlbumClips:[_content images] toData:entities withSearch:nil];
	}else if(_album) {
		[self converAlbumClips:_album.clips toData:entities withSearch:nil];
	}
	else if(_pureURLs) {
		for (NSString *url in _pureURLs) {
			[entities addObject:[[ImageEntity alloc] initWithData:url desc: @""]];
		}
	}
//	else if(_articleDicts) {
//		[_articleDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//			NSString *desc = obj[@"desc"];
//			NSString *url = obj[@"url"];
//			if(desc && [desc length] != 0) {
//				[entities addObject:[[ImageEntity alloc] initWithData:@"" desc:desc]];
//			}
//			[entities addObject:[[ImageEntity alloc] initWithData:url desc:@""]];
//		}];
//	}else if(_articleURLs) {
//		for (NSString *url in _articleURLs) {
//			[entities addObject:[[ImageEntity alloc] initWithData:url desc: @""]];
//		}
//	}
	_data = [entities mutableCopy];
}

- (void)converAlbumClips:(NSArray *)clips toData:(NSMutableArray *)entities withSearch:(NSString *)keywords{
	NSMutableArray *pureURL = @[].mutableCopy;
	[clips enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ImageEntity *entity = (ImageEntity *)obj;
		if(!keywords || [entity.desc rangeOfString:_searchKeywords options:NSCaseInsensitiveSearch].location != NSNotFound)
		{
			NSString *desc = entity.desc;
			NSString *url = entity.url;
			if(desc && [desc length] != 0) {
				[entities addObject:[[ImageEntity alloc] initWithData:@"" desc:desc]];
			}
			[entities addObject:[[ImageEntity alloc] initWithData:url desc:@"" tag:idx]];
			[pureURL addObject:url];
		}
	}];
	_pureURLs = [pureURL copy];
}

- (void)initHeader {
	
	if (_data.count == 0) {
		return;
	}
	
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

- (void)setupNavItem {
	UIBarButtonItem *button;
	if(_fetchMode) {
		button = [[UIBarButtonItem alloc] initWithTitle:@"收藏全部" style:UIBarButtonItemStyleBordered target:self action:@selector(prepareToSaveAll)];
	}else if([self isInAlbum]) {
		button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showOverallActionsheet)];
	}else {
		button = [[UIBarButtonItem alloc] initWithTitle:@"显示" style:UIBarButtonItemStyleBordered target:self action:@selector(showRatioActionsheet)];
	}
	self.navigationItem.rightBarButtonItem = button;
	
	if(self.modalPresentationStyle == UIModalPresentationCurrentContext) {
		button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissSelf)];
		self.navigationItem.leftBarButtonItem = button;
	}
}

- (void)dismissSelf {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isVisible {
	return [self isViewLoaded] && self.view.window;
}

#pragma mark - (User Interaction)

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (_data.count > 0) {
		return 1;
	} else {
		UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
		messageLabel.text = @"无内容显示";
		messageLabel.textColor = [UIColor lightGrayColor];
		messageLabel.numberOfLines = 0;
		messageLabel.textAlignment = NSTextAlignmentCenter;
		messageLabel.font = [UIFont systemFontOfSize:20];
		[messageLabel sizeToFit];
		self.tableView.backgroundView = messageLabel;
		return 0;
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ImageEntity *entity = _data[indexPath.row];
	
	if([entity.url length] == 0) {
		TitleCell *cell = [tableView dequeueReusableCellWithIdentifier:TitleCellIdentifier];
		[self configureTitleCell:cell atIndexPath:indexPath isForHeight:false];
		return cell;
	}else {
		ClipCell *cell = [tableView dequeueReusableCellWithIdentifier:_clipCellType];
		[self configureCell:cell atIndexPath:indexPath isForHeight:false];
		return cell;
	}
}

- (void)configureCell:(ClipCell *)cell atIndexPath:(NSIndexPath *)indexPath isForHeight:(BOOL)isForHeight {
	cell.fd_enforceFrameLayout = YES; // Enable to use "-sizeThatFits:"
	cell.delegate = self;
	cell.cellHeight = _cellHeight;
	[cell setCellData: _data[indexPath.row] isForHeight:isForHeight];
}

- (void)configureTitleCell:(TitleCell *)cell atIndexPath:(NSIndexPath *)indexPath isForHeight:(BOOL)isForHeight {
	cell.fd_enforceFrameLayout = YES; // Enable to use "-sizeThatFits:"
	[cell setCellData: _data[indexPath.row] isForHeight:isForHeight];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	ImageEntity *entity = _data[indexPath.row];
	
	if([entity.url length] == 0) {
		return [tableView fd_heightForCellWithIdentifier:TitleCellIdentifier cacheByIndexPath:indexPath configuration:^(id cell) {
			[self configureTitleCell:cell atIndexPath:indexPath isForHeight:true];
		}];
	}else{
		return [tableView fd_heightForCellWithIdentifier:_clipCellType cacheByIndexPath:indexPath configuration:^(id cell) {
			[self configureCell:cell atIndexPath:indexPath isForHeight:true];
		}];
	}
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

#pragma mark - Favorite
- (void)setFavoriate:(NSString *)url {
	[_cblService setFavoriate:url];
}
- (void)unsetFavoriate:(NSString *)url {
	[_cblService unsetFavoriate:url];
}
- (BOOL)isFavoriate:(NSString *)url {
	return [_cblService isFavoriate:url];
}

#pragma mark - Comments

- (void)fetchPostComments:(BOOL)isRefresh {
	
	NSString *id_post = [self postID];
	
	if(id_post){
		[_lbService getCommentsSummaryByPostID:id_post isRefresh:isRefresh success:^(NSArray *list) {
			[self generateCommentList:list];
		} failure:^{
		}];
	}else if(_pureURLs.count > 0) {
		[_lbService getCommentsSummaryByClipIDs:[_pureURLs copy] isRefresh:isRefresh title:_header success:^(NSArray *list) {
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
	
	_commentList = [dict copy];
	
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
	if(_commentList == nil) {
		return nil;
	}
	
	NSString *qty = [[_commentList objectForKey:clipID] stringValue];
	return qty? qty: @"";
}

- (void)showComments:(NSString *)clipID {
	EBCommentsViewController *clipCtr = [[EBCommentsViewController alloc] init];
	[clipCtr setClipID:clipID];
	[clipCtr setDelegate:self];
	clipCtr.modalPresentationStyle = UIModalPresentationOverFullScreen;
	[self presentViewController:clipCtr animated:YES completion:nil];
}

//- (void)closeCommentView {
//	[self setDownloadLimit:YES];
//}

#pragma mark - Share

- (void)shareClip:(NSURL *)clipID {
	[_lbService shareWithClipID:clipID];
}

#pragma mark - Album & Favorite

- (void)showBottomAlbumPopup {
	STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:[[UIStoryboard storyboardWithName:@"favorite" bundle:nil] instantiateViewControllerWithIdentifier:@"addList"]];
	
	_popCtr = popupController;
	popupController.style = STPopupStyleBottomSheet;
	
	[popupController.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewDidTap)]];
	
	[[STPopupNavigationBar appearance] setTintColor: [UIColor whiteColor]];
	[[STPopupNavigationBar appearance] setBarTintColor:CLIPLAY_COLOR];
	[STPopupNavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor]};
	
	[popupController presentInViewController:self];
}

- (void)backgroundViewDidTap {
	[self.popCtr dismiss];
}

- (void)showNewAlbumFormWithTitle:(NSString *)title {
	UIAlertView* alert= [[UIAlertView alloc] initWithTitle:@"新建收藏夹"
												   message:@"请输入名称:"
												  delegate:self
										 cancelButtonTitle:@"取消"
										 otherButtonTitles:@"确定", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alert textFieldAtIndex:0].text = title;
	[alert show];
}

- (void)saveClipToAlbumWithDesc:(NSString *)desc {
	if([_cblService addClip:[self urlForSeletedClip] toAlum:_albumToAdd withDesc:desc]) {
		[self setCollected:[self urlForSeletedClip]];
		[((ClipCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_indexOfSelectedClip inSection:0]]) selectAlbumButton];
	}
}

- (NSString *)urlForSeletedClip {
	ImageEntity *entity = _data[_indexOfSelectedClip];
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
	[_cblService addClips:_pureURLs toAlum:_albumToAdd];
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
				[self showNewAlbumFormWithTitle:_header];
			}
		}else{
			if(_albumToAdd){
				[self showClipDescPopup:@""];
			}else {
				[self showNewAlbumFormWithTitle:@""];
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
	NSInteger clipIndexInAlbum = ((ImageEntity *)_data[_indexOfSelectedClip]).tag;
	NSString *origDesc = ((ImageEntity *)_album.clips[clipIndexInAlbum]).desc;
	
	//No need to change if not changed
	if([origDesc isEqualToString:newDesc]) {
		return;
	}
	
	if([_cblService modifyClipDesc:newDesc withIndex:clipIndexInAlbum forAlbum:_album]) {
		[self refreshScreen:YES];
	}
}

- (void)deleteClip {
	NSInteger clipIndexInAlbum = ((ImageEntity *)_data[_indexOfSelectedClip]).tag;
	if([_cblService deleteClipWithIndex:clipIndexInAlbum forAlbum:_album]) {
		[self refreshScreen:YES];
	}
}

- (void)showClipDescPopup:(NSString *)desc {
	AlbumAddClipDescViewController *ctr = [[UIStoryboard storyboardWithName:@"favorite" bundle:nil] instantiateViewControllerWithIdentifier:@"addDesc"];
	
	[ctr setUrl:[self urlForSeletedClip]];
	ctr.currDesc = desc;
	ctr.delegate = self;
	ctr.modalPresentationStyle = UIModalPresentationCurrentContext;
	
	AutoRotateNavController *navigationController =
	[[AutoRotateNavController alloc] initWithRootViewController:ctr];
	
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)clipDescCallbackWithDesc:(NSString *)desc{
	if(_actionType == addToAlbum) {
		[self saveClipToAlbumWithDesc:desc];
	}else if(_actionType == modifyDesc) {
		[self modifyClipDesc:desc];
	}
}

- (void)prepareForDescModify {
	NSString *curDesc = @"";
	if(_indexOfSelectedClip != 0) {
		ImageEntity *entity = _data[_indexOfSelectedClip - 1];
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
	ctr.delegate = self;
	
	AutoRotateNavController *navigationController =
	[[AutoRotateNavController alloc] initWithRootViewController:ctr];
	
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)albumInfoCallbackWithName:(NSString *)name withDesc:(NSString *)desc{
	[self updateAlbumInfoWithTitle:name withDesc:desc];
}

- (void)updateAlbumInfoWithTitle:(NSString *)title withDesc:(NSString *)desc {
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

- (void)setClipRatio:(float)ratio {
	[self setCellHeight:ceil((kScreenWidth) * ratio)];
}

- (void)changeClipRatioWithWidth:(CGFloat)width withHeight:(CGFloat)height {
	[self setClipWidth:width withHeight:height];
	[self refreshScreen:NO];
}

- (void)changeClipRatio:(float)ratio {
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

- (void)setRatioSetting:(float)ratio {
	Configuration *config = [Configuration load];
	config.displayRatio = [NSNumber numberWithFloat:ratio];
	[config save];
}

- (float)getRatioSetting {
	Configuration *config = [Configuration load];
	return [config.displayRatio floatValue];
}

#pragma mark - Animation
- (void)slowPlayWithURL:(NSString *)url {
	[self recordSlowPlayWithUrl:url];
	
	ClipPlayController *clipCtr = [ClipPlayController new];
	
	clipCtr.clipURL = url;
	clipCtr.favorite = YES;
	clipCtr.showLike = NO;
	clipCtr.standalone = NO;
	
	clipCtr.modalPresentationStyle = UIModalPresentationCurrentContext;
	clipCtr.delegate = self;
	_interactiveTransition = [[SwipeUpInteractiveTransition alloc]init:clipCtr];
	clipCtr.transitioningDelegate = self;
	
	[self presentViewController:clipCtr animated:YES completion:nil];
}

- (void)recordSlowPlayWithUrl:(NSString *)url {
	[_lbService recordSlowPlayWithClipID:url];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
	return [[PresentedAnimation alloc]init];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return [[DismissAnimation alloc]init];
}

-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
	return (self.interactiveTransition.isInteracting ? self.interactiveTransition : nil);
}

//- (void)showPopup {
//
//	NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
//	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
//	paragraphStyle.alignment = NSTextAlignmentCenter;
//
//	NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"操作说明" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle}];
//
//	NSAttributedString *lineOne= [[NSAttributedString alloc] initWithString:@"点击图片进入滑屏慢放模式" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : CLIPLAY_COLOR, NSParagraphStyleAttributeName : paragraphStyle}];
//
//	NSAttributedString *lineTwo = [[NSAttributedString alloc] initWithString:@"点击播放/暂停，滑屏拖动播放" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSParagraphStyleAttributeName : paragraphStyle}];
//
//	CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
//	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//	button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
//	[button setTitle:@"知道了" forState:UIControlStateNormal];
//	button.backgroundColor = CLIPLAY_COLOR;
//	button.layer.cornerRadius = 4;
//
//	UILabel *titleLabel = [[UILabel alloc] init];
//	titleLabel.numberOfLines = 0;
//	titleLabel.attributedText = title;
//
//	UILabel *lineOneLabel = [[UILabel alloc] init];
//	lineOneLabel.numberOfLines = 0;
//	lineOneLabel.attributedText = lineOne;
//
//	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tip"]];
//
//	UILabel *lineTwoLabel = [[UILabel alloc] init];
//	lineTwoLabel.numberOfLines = 0;
//	lineTwoLabel.attributedText = lineTwo;
//
//	CNPPopupController *popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, lineOneLabel, lineTwoLabel, imageView, button]];
//	popupController.theme = [CNPPopupTheme defaultTheme];
//	popupController.theme.popupStyle = CNPPopupStyleCentered;
//	popupController.theme.cornerRadius = 10.0f;
//
//	popupController.delegate = self;
//
//	button.selectionHandler = ^(CNPPopupButton *button){
//		[popupController dismissPopupControllerAnimated:YES];
//	};
//
//	[popupController presentPopupControllerAnimated:YES];
//}
//
//- (void)popupControllerDidDismiss:(CNPPopupController *)controller {
//	if(!self.infoButton.selected) [self.infoButton select];
//}
//
//- (void)tappedButton:(DOFavoriteButton *)sender {
//	[self showPopup];
//}

@end
