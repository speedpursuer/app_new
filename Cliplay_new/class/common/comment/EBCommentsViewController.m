//
//  EBCommentsViewController.m
//  Cliplay
//
//  Created by 邢磊 on 16/8/12.
//
//

#import "EBCommentsViewController.h"
#import "EBPhotoCommentProtocol.h"
#import "EBCommentCell.h"
#import "EBCommentsView.h"
#import "EBCommentsTableView.h"
#import <FontAwesomeKit/FAKIonIcons.h>
#import "UIGestureRecognizer+YYAdd.h"
#import "EBShadedView.h"

@interface EBCommentsViewController() {
	LBService *lbService;
}
//@property (nonatomic, strong) FRDLivelyButton *closeButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (weak, readwrite) UIView *activityIndicator;
@property (nonatomic, strong) UILabel *cancelButton;
@property (nonatomic, strong) EBShadedView *commentShadedView;
//@property (strong) MyLBService *lbService;
@end

@implementation EBCommentsViewController

- (id)init
{
	self = [super init];
	lbService = [LBService sharedManager];
	[lbService setCommentdelegate:self];
//	service = [FakeService new];
//	[service setDelegate:self];
	return self;
}

- (void)initialize
{
	CGRect viewFrame = [[UIScreen mainScreen] bounds];
	UIView *mainView = [[UIView alloc] initWithFrame:viewFrame];
	[self setView:mainView];
}

- (void)viewDidLoad {	
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
//	_size = self.view.frame.size;
	[self loadLowerShadedView];
	[self loadUpperShadedView];
	[self.view addSubview:[self getCommentsView]];
//	[self loadCommentShadedView];
	[self loadCloseButton];
	[self showActivityIndicator];
	[self loadCancelButton];
	[self beginObservations];
//	[self hideBar];
	[self startFetchingResults];
}

- (void)dealloc
{
//	[self showBar];
	[self stopObservations];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.delegate fetchPostComments:YES];
}

- (void)loadUpperShadedView {
	CGFloat gradientWidth = self.view.frame.size.width;
	CGFloat gradientHeight = 150;
	CGRect gradientRect = CGRectMake(0, 0, gradientWidth, gradientHeight);
	EBShadedView *upperGradient = [EBShadedView upperGradientWithFrame:gradientRect];
	
	[upperGradient setAutoresizingMask:UIViewAutoresizingFlexibleWidth|
	 UIViewAutoresizingFlexibleBottomMargin |
	 UIViewAutoresizingFlexibleHeight];
	
	[self.view addSubview:upperGradient];
//	[self setUpperGradient:upperGradient];
}

- (void)loadLowerShadedView {
	CGFloat gradientWidth = self.view.frame.size.width;
	CGFloat gradientHeight = 150;
	CGRect gradientRect = CGRectMake(0,
									 (self.view.frame.size.height - gradientHeight)+1,
									 gradientWidth,
									 gradientHeight);
	EBShadedView *lowerGradient = [EBShadedView lowerGradientWithFrame:gradientRect];
	
	[lowerGradient setAutoresizingMask:UIViewAutoresizingFlexibleWidth|
	 UIViewAutoresizingFlexibleTopMargin|
	 UIViewAutoresizingFlexibleHeight];
	
	[self.view addSubview:lowerGradient];
	//	[self setLowerGradient:lowerGradient];
}

- (void)loadCommentShadedView {
	CGFloat gradientWidth = self.view.frame.size.width;
	CGFloat gradientHeight = 150;
	CGRect gradientRect = CGRectMake(0, 0, gradientWidth, gradientHeight);
	EBShadedView *upperGradient = [EBShadedView upperGradientWithFrame:gradientRect];
	
	[upperGradient setAutoresizingMask:UIViewAutoresizingFlexibleWidth|
	 UIViewAutoresizingFlexibleBottomMargin |
	 UIViewAutoresizingFlexibleHeight];
	
	[self.view addSubview:upperGradient];
	[self setCommentShadedView:upperGradient];
	[upperGradient setHidden:YES];
}

- (void)loadCloseButton {
	CGSize size = CGSizeMake(40, 40);
	_closeButton = [[UIButton alloc] initWithFrame:CGRectMake(6,20,size.width, size.height)];
	
	FAKIonIcons *icon = [FAKIonIcons iosCloseEmptyIconWithSize:70];
	[icon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
//	[_closeButton setBackgroundColor:[UIColor whiteColor]];
//	[_closeButton setTintColor:[UIColor whiteColor]];
	[_closeButton setImage:[icon imageWithSize:size] forState:UIControlStateNormal];
	[icon addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor]];
	[_closeButton setImage:[icon imageWithSize:size] forState:UIControlStateHighlighted];
	[_closeButton addTarget:self action:@selector(closeCommentsView) forControlEvents:UIControlEventTouchUpInside];

	
//	[_closeButton setStyle:kFRDLivelyButtonStyleClose animated:NO];
//	[_closeButton addTarget:self action:@selector(closeCommentsView) forControlEvents:UIControlEventTouchUpInside];
//	[_closeButton setOptions:@{ kFRDLivelyButtonLineWidth: @(2.0f),
//								kFRDLivelyButtonColor: [UIColor whiteColor]}];
//	
	[self.view addSubview:_closeButton];
}

- (void)loadCancelButton {
	_cancelButton = [UILabel new];
	_cancelButton.frame = CGRectMake(10, 30, 100, 30);
	_cancelButton.textAlignment = NSTextAlignmentLeft;
	_cancelButton.text = NSLocalizedString(@"Cancel", @"Common text");
	_cancelButton.textColor = [UIColor whiteColor];
	_cancelButton.hidden = YES;
	_cancelButton.userInteractionEnabled = YES;
	[self.view addSubview:_cancelButton];
	__weak typeof(self) _self = self;
	UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
		[_self.commentsView cancelCommenting];
	}];
	[_cancelButton addGestureRecognizer:g];
}

- (void)beginObservations {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidChangeFrame:)
												 name:UIKeyboardWillChangeFrameNotification
											   object:nil];
}

- (void)stopObservations
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - (Comments)
- (void)setCommentsHidden:(BOOL)commentsHidden
{
	commentsHidden ? [self hideComments] : [self showComments];
}


- (void)hideComments
{
	//self.commentsAreHidden = YES;
	[self.commentsView setHidden:YES];
}

- (void)showComments
{
	//self.commentsAreHidden = NO;
	[self.commentsView setHidden:NO];
	[self.commentsView setNeedsDisplay];
}

- (void)cancelCommentingWithNotification:(NSNotification *)aNotification
{
	[self.commentsView cancelCommenting];
}

- (void)loadComments:(NSArray *)comments
{
	[self setComments:comments];
	[self.commentsView reloadComments];
}

- (void)setCommentingEnabled:(BOOL)enableCommenting
{
	if(enableCommenting){
		[self.commentsView enableCommenting];
	} else {
		[self.commentsView disableCommenting];
	}
}

- (void)startCommenting
{
	[self.commentsView startCommenting];
}

#pragma mark - Comments Tableview Datasource & Delegate

- (void)startFetchingResults
{
	[super startFetchingResults];
	
	[lbService getCommentsByClipID:self.clipID offset:0 success:^(NSArray *results, BOOL hasMore) {
		[self didFetchResults:results haveMoreData:hasMore];
		[self hideActivityIndicator];
	} failure:^{
		[self failedToGetComments];
		[self hideActivityIndicator];
	}];
}

// Must be implemented
- (void)startFetchingNextResults
{
	[super startFetchingNextResults];
	
	[lbService getCommentsByClipID:self.clipID offset:self.results.count success:^(NSArray *results, BOOL hasMore) {
		[self didFetchNextResults:results haveMoreData:hasMore];
	} failure:^{
		[self failedToGetComments];
	}];
}

- (void)failedToGetComments {
	[self didFailedToFetchResults];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"获取数据失败" message:@"请稍候再试" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
	[alertView show];
}

- (void)deleteCellWithNotification:(NSNotification *)notification
{
	UITableViewCell *cell = notification.object;
	
	if([cell isKindOfClass:[UITableViewCell class]] == NO){
		return;
	}
	
	NSIndexPath *indexPath = [self.commentsView.tableView indexPathForCell:cell];
	
	if(indexPath){
		id<EBPhotoCommentProtocol>deletedComment = self.comments[indexPath.row];
		
		NSMutableArray *remainingComments = [NSMutableArray arrayWithArray:self.comments];
		[remainingComments removeObjectAtIndex:indexPath.row];
		[self setComments:[NSArray arrayWithArray:remainingComments]];
		
		[self.commentsView.tableView beginUpdates];
		[self.commentsView.tableView deleteRowsAtIndexPaths:@[indexPath]
										   withRowAnimation:UITableViewRowAnimationLeft];
		[self.commentsView.tableView endUpdates];
		
		//		[self.delegate photoViewController:self didDeleteComment:deletedComment];
		
		[self.commentsView.tableView reloadData];
		
		//[self reloadData];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//	return self.results.count;
//}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	JTTABLEVIEW_cellForRowAtIndexPath
	static NSString *CellIdentifier = @"Cell";
	EBCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	id <EBPhotoCommentProtocol> comment = self.results[indexPath.row];
	NSAssert([comment conformsToProtocol:@protocol(EBPhotoCommentProtocol)],
			 @"Comment objects must conform to the EBPhotoCommentProtocol.");
	[self configureCell:cell
		 atRowIndexPath:indexPath
			withComment:comment];
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	JTTABLEVIEW_heightForRowAtIndexPath
	const CGFloat MinimumRowHeight = 60;
	
	id<EBPhotoCommentProtocol> comment = self.results[indexPath.row];
	CGFloat rowHeight = 0;
	NSString *textForRow = nil;
	
	if([comment respondsToSelector:@selector(attributedCommentText)] &&
	   [comment attributedCommentText]){
		textForRow = [[comment attributedCommentText] string];
	} else {
		textForRow = [comment commentText];
	}
	
	//Get values from the comment cell itself, as an abstract class perhaps.
	//OR better, from reference cells dequeued from the table
	//http://stackoverflow.com/questions/10239040/dynamic-uilabel-heights-widths-in-uitableviewcell-in-all-orientations
	/*
	 NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:textForRow attributes:@{NSFontAttributeName:@"HelveticaNeue-Light"}];
	 
	 CGRect textViewRect = [attributedText boundingRectWithSize:(CGSize){285, CGFLOAT_MAX}
	 options:NSStringDrawingUsesLineFragmentOrigin
	 context:nil];
	 CGSize textViewSize = textViewRect.size;
	 */
	
//	CGRect textViewSize = [textForRow boundingRectWithSize:CGSizeMake(271, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:13]} context:nil];
	
	CGRect textViewSize = [textForRow boundingRectWithSize:CGSizeMake(280, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13]} context:nil];
	
//	static CGFloat padding = 10.0;
//	
//	CGFloat availableWidth = CGRectGetWidth(self.commentsView.tableView.frame);
//	
//	CGSize textSize = CGSizeMake(availableWidth - (2 * padding) - 29, CGFLOAT_MAX); //
//	
//	textViewSize = [textForRow boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:16]} context:nil];
	
	
	CGFloat textViewHeight = 25;
	const CGFloat additionalSpace = MinimumRowHeight - textViewHeight + 10;
	
	rowHeight = textViewSize.size.height + additionalSpace;
	
//#if defined(__LP64__) && __LP64__
//	rowHeight = ceil(textViewSize.size.height) + additionalSpace;
//#else
//	rowHeight = ceilf(textViewSize.size.height) + additionalSpace;
//#endif
	
	return rowHeight;
}

- (void)configureCell:(EBCommentCell *)cell
	   atRowIndexPath:(NSIndexPath *)indexPath
		  withComment:(id<EBPhotoCommentProtocol>)comment
{
	EBCommentsView *commentsView = [self getCommentsView];
	
	//	BOOL configureCell = [self.delegate respondsToSelector:@selector(photoViewController:shouldConfigureCommentCell:forRowAtIndexPath:withComment:)] ?
	//	[self.delegate photoViewController:self shouldConfigureCommentCell:cell forRowAtIndexPath:indexPath withComment:comment] : YES;
	
	BOOL configureCell = YES;
	
	if([cell isKindOfClass:[EBCommentCell class]] && configureCell){
		[cell setComment:comment];
		[cell setHighlightColor:commentsView.commentCellHighlightColor];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell setBackgroundColor:[UIColor clearColor]];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	if (action == @selector(copy:)) {
		return YES;
	}
	
	if (action == @selector(delete:)) {
		id<EBPhotoCommentProtocol> commentToDelete = self.results[indexPath.row];
		if([self canDeleteComment:commentToDelete]){
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)canDeleteComment: (id<EBPhotoCommentProtocol>)comment {
	return TRUE;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	if (action == @selector(copy:)) {
		id<EBPhotoCommentProtocol> comment = self.results[indexPath.row];
		NSString *copiedText = nil;
		if([comment respondsToSelector:@selector(attributedCommentText)]){
			copiedText = [[comment attributedCommentText] string];
		}
		
		if(copiedText == nil){
			copiedText = [comment commentText];
		}
		
		[[UIPasteboard generalPasteboard] setString:copiedText];
	} else if (action == @selector(delete:)) {
		[self tableView:tableView
	 commitEditingStyle:UITableViewCellEditingStyleDelete
	  forRowAtIndexPath:indexPath];
	}
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		id<EBPhotoCommentProtocol>deletedComment = self.results[indexPath.row];
		
		NSMutableArray *remainingComments = [NSMutableArray arrayWithArray:self.comments];
		[remainingComments removeObjectAtIndex:indexPath.row];
		[self setComments:[NSArray arrayWithArray:remainingComments]];
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		//		[self.delegate photoViewController:self didDeleteComment:deletedComment];
		[self deleteComment:deletedComment];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
}

- (void)deleteComment: (id<EBPhotoCommentProtocol>)deletedComment {
	
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//	[self.commentsView cancelCommenting];
	
	// Navigation logic may go here. Create and push another view controller.
	/*
	 DetailViewController *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"Nib name" bundle:nil];
	 // ...
	 // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 */
	//	NSLog(@"select row");
	
}

#pragma mark - CommentDelegate

- (void)willPerformAction {
	[self commentingState];
}

- (void)didPerformActionWithResult:(id)result error:(BOOL)error {
	if(!error) {
		[self.results insertObject:result atIndex:0];
		[self.tableView reloadData];
	}
	[self quitCommentingState:error];
}

- (void)didShowLoginSelection {
	[self hideActivityIndicator];
	[self enablePostButton];
}

- (void)didSelectLogin {
	[self showActivityIndicator];
	[self disablePostButton];
}


- (void)commentsView:(id)view didPostNewComment:(NSString *)commentText
{
	if(![[commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		if(commentText)
		[lbService commentWithClipID:self.clipID
							withText:commentText
		];
	}else{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法发表评论" message:@"评论内容不能为空" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
		
		[alertView show];
	}
}

//- (void)didSubmitComment:(ModelComment *)model hasError:(BOOL)hasError {
//	
//	if(!hasError) {
//		[self.results insertObject:model atIndex:0];
//		[self.tableView reloadData];
//	}
//	[self quitCommentingState:hasError];
//}

- (void)commentingState {
	[self showActivityIndicator];
	[self.commentsView cancelCommenting];
	[self disablePostButton];
	[self.commentsView.tableView setUserInteractionEnabled:false];
}

- (void)quitCommentingState:(BOOL)hasError {
	[self hideActivityIndicator];
//	[self.commentsView.postButton setEnabled:true];
	[self enablePostButton];
	[self.commentsView.tableView setUserInteractionEnabled:true];
	if(!hasError) {
		
		[self.commentsView.commentTextView setText:nil];
//		[self.commentsView.commentTextView resignFirstResponder];
		[self.commentsView setInputPlaceholderEnabled:YES];
		[self.commentsView setPostButtonHidden:YES];
		
		[self.commentsView.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
	}
//	else{
//		//Need to manually set back
//		[self.commentsView.postButton setAlpha:1];
//	}
}

- (void)enablePostButton {
	[self.commentsView.postButton setEnabled:true];
	[self.commentsView.postButton setAlpha:1];
}

- (void)disablePostButton {
	[self.commentsView.postButton setEnabled:false];
	[self.commentsView.postButton setAlpha:0.66];
}

#pragma mark - Comments UITextViewDelegate

- (BOOL)hasText:(UITextView *)textView {
	return (textView.text != nil && ![textView.text isEqualToString:@""]);
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	//clear out text
//	[textView setText:nil];
	return YES;
	
//	if(textView.text != nil) {	
//	if(textView.text == nil || [textView.text isEqualToString:@""]) {
//		return YES;
//	}else {
//		return NO;
//	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	//	[[NSNotificationCenter defaultCenter] postNotificationName:EBPhotoViewControllerDidBeginCommentingNotification object:self];
	
//	if (![self hasText:textView]) {
//		[self.commentsView setInputPlaceholderEnabled:NO];
//	}
	
//	[self.commentsView setPostButtonHidden:NO];
	[self.closeButton setHidden:YES];
	[self.cancelButton setHidden:NO];
//	[self.commentShadedView setHidden:NO];
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self.closeButton setHidden:NO];
	[self.cancelButton setHidden:YES];
//	[self.commentShadedView setHidden:YES];
	//	[[NSNotificationCenter defaultCenter] postNotificationName:EBPhotoViewControllerDidEndCommentingNotification object:self];
//	[self.commentsView setInputPlaceholderEnabled:YES];
//	[self.commentsView setPostButtonHidden:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	//check message length
	return [[textView text] length] - range.length + text.length > COMMENT_CHART_LIMIT? NO: YES;
}


- (void)textViewDidChange:(UITextView *)textView
{
	if(textView.isFirstResponder){
		
		if(textView.text == nil || [textView.text isEqualToString:@""]){
			[self.commentsView setPostButtonHidden:YES];
			[self.commentsView setInputPlaceholderEnabled:YES];
		} else {
			[self.commentsView setPostButtonHidden:NO];
			[self.commentsView setInputPlaceholderEnabled:NO];
		}
	}
}

#pragma mark - Util

- (UITextView *)getTextView {
	return self.commentsView.commentTextView;
}

- (EBCommentsView *)getCommentsView {
	
	//	CGSize tableViewSize = CGSizeMake(self.view.frame.size.width,
	//									  self.view.frame.size.height);
	
	if ([self commentsView]) {
		return [self commentsView];
	}else {
		
		CGRect tableViewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
		
		EBCommentsView *commentsView = [[EBCommentsView alloc] initWithFrame:tableViewFrame];
		
		[commentsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
		
//		[commentsView.tableView setDataSource:self];
//		[commentsView.tableView setDelegate:self];
		[commentsView setCommentCellHighlightColor:[self commentCellTintColor]];
		
		static NSString *CellReuseIdentifier= @"Cell";
		NSAssert([EBCommentCell class],
				 @"If an EBPhotoPagesFactory object doesn't specify a UINib for Comment UITableViewCells it must at least specify a Class to register.");
		[commentsView.tableView registerClass:[EBCommentCell class] forCellReuseIdentifier:CellReuseIdentifier];
		[commentsView.commentTextView setDelegate:self];
		[commentsView setCommentsDelegate:self];
		
		[commentsView setNeedsLayout];
		
		UITableViewCell *loader = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
														 reuseIdentifier:@"loader"];
				
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]
													  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[activityIndicator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|
		 UIViewAutoresizingFlexibleLeftMargin|
		 UIViewAutoresizingFlexibleRightMargin|
		 UIViewAutoresizingFlexibleBottomMargin];
		[activityIndicator setHidesWhenStopped:NO];
		[activityIndicator startAnimating];
		
		[activityIndicator setCenter:loader.center];
		[loader.contentView addSubview:activityIndicator];
		
		[self setNextPageLoaderCell:loader];
		
		[self setTableView:commentsView.tableView];
		
		[self setCommentsView: commentsView];
		
//		[commentsView startCommenting];
		
		[self setCommentingEnabled:TRUE];
		
		return commentsView;
	}
}

- (UIColor *)commentCellTintColor
{
	UIColor *photoPagesColor = [self photoPagesTintColor];
	return [photoPagesColor colorWithAlphaComponent:0.35];
}

- (UIColor *)photoPagesTintColor
{
	return [UIColor colorWithWhite:0.99 alpha:1.0];
}

- (void)closeCommentsView {
	[self dismissViewControllerAnimated:YES completion:nil];
//	[_delegate closeCommentView];
}

- (void)showActivityIndicator
{
	if(self.activityIndicator){
		return;
	}
	
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]
												  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[activityIndicator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|
	 UIViewAutoresizingFlexibleLeftMargin|
	 UIViewAutoresizingFlexibleRightMargin|
	 UIViewAutoresizingFlexibleBottomMargin];
	[activityIndicator setHidesWhenStopped:NO];
	[activityIndicator startAnimating];
	
	[activityIndicator setCenter:self.view.center];
	[self.view addSubview:activityIndicator];
	[self setActivityIndicator:activityIndicator];
	
	
	if([activityIndicator isKindOfClass:[UIActivityIndicatorView class]]){
		[activityIndicator setAlpha:0];
		[UIView animateWithDuration:0.1
							  delay:0
							options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 [activityIndicator setAlpha:1];
						 }completion:nil];
	}
	
}

- (void)hideActivityIndicator
{
	if([self.activityIndicator isKindOfClass:[UIActivityIndicatorView class]]){
		UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)self.activityIndicator;
		[indicator stopAnimating];
		[self.activityIndicator removeFromSuperview];
//		[UIView animateWithDuration:0.5
//							  delay:0.0
//							options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
//						 animations:^{
//							 [indicator setAlpha:0];
//						 }completion:^(BOOL finished){
//							 [indicator stopAnimating];
//							 [self.activityIndicator removeFromSuperview];
//						 }];
	} else {
		[self.activityIndicator removeFromSuperview];
	}
	
	[self setActivityIndicator:nil];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
	NSDictionary* info = [notification userInfo];
	CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
	NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval duration;
	[value getValue:&duration];
	
//	NSLog(@"Keyboard frame with conversion is %f,%f,%f,%f", keyboardFrame.origin.x, keyboardFrame.origin.y, keyboardFrame.size.width, keyboardFrame.size.height);
	
	[self.commentsView updateTableViewWithHeight:(self.commentsView.frame.size.height - keyboardFrame.origin.y)];
	
	CGPoint newCenter = CGPointMake(self.commentsView.frame.size.width*0.5,
									keyboardFrame.origin.y - (self.commentsView.frame.size.height*0.5));
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationCurveEaseOut|
	 UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 [self.commentsView setCenter:newCenter];
					 }completion:nil];
}

- (void)showBar {
	[[[self navigationController] navigationBar] setHidden:NO];
	[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

- (void)hideBar {
	[[[self navigationController] navigationBar] setHidden:YES];
	[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

@end
