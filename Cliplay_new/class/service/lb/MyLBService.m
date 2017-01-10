//
//  MyLBService.m
//  Cliplay
//
//  Created by 邢磊 on 16/8/18.
//
//

#import "MyLBService.h"
#import "ModelComment.h"
#import "User.h"
#import <WeiboSDK/WeiboSDK.h>
#import <WeiboSDK/WeiboUser.h>
#import <YYWebImage/YYWebImage.h>
#import "MRProgress.h"
#import "FCUUID.h"

static NSInteger const pageSize = 11;

@implementation MyLBService {
	LBModelRepository *clientRep;
	LBPersistedModelRepository *commentRep;
	LBModelRepository *postRep;
	LBModelRepository *visitRep;
	LBModelRepository *apiRep;
	MyLBAdapter *adapter;
	TencentOAuth *oauth;
	NSString *newCommentText;
	NSString *newCommentClipID;
	NSURL *sharedClipID;
	NSString *sharedText;
	User *user;
	AAShareBubbles *shareBubbles;
	NSInteger shareTimes;
	REComposeViewController *composeView;
	MRProgressOverlayView *progressView;
}

#pragma mark - Init
+ (id)sharedManager {
	static MyLBService *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}

- (id)init {
	if (self = [super init]) {
		adapter = (MyLBAdapter*)[LBRESTAdapter adapterWithURL:[NSURL URLWithString:serverAPIRoot]];
		commentRep = [adapter repositoryWithPersistedModelName:@"comments"];
		clientRep = [adapter repositoryWithModelName:@"clients"];
		postRep = [adapter repositoryWithModelName:@"posts"];
		visitRep = [adapter repositoryWithModelName:@"visits"];
		apiRep = [adapter repositoryWithModelName:@"apis"];
		
		oauth = [[TencentOAuth alloc] initWithAppId:tencentAppID
											 andDelegate:self];
		user = [User loadWithDefault];
		[self registerDeviceWithSuccess:nil failure:nil];
		
		[WeiboSDK enableDebugMode:YES];
		[WeiboSDK registerApp:weiboAppID];
	}
	return self;
}

- (void)registerDeviceWithSuccess:(void(^)())success
						  failure:(void(^)())failure
{
	if(adapter.accessToken == nil) {
		NSString *uuid = [FCUUID uuidForDevice];
		[clientRep invokeStaticMethod:@"register"
							parameters:@{@"uuid":uuid}
							   success:^(id value) {
								   
								   NSString *token = (NSString*)[[value objectForKey:@"data"] objectForKey:@"accesstoken"];
								   
								   adapter.accessToken = token;
								   [self recordAppInstall];
								   if(success != NULL) {
									   success();
								   }
							   }
							   failure:^(NSError *error) {
								   if(failure != NULL) {
									   failure();
								   }
							   }
		];
	}else {
		[self recordAppStart];
	}
}

#pragma mark - Public APIs

- (void)getCommentsByClipID:(NSString *)clipID
					 offset:(NSInteger)offset
					success:(void(^)(NSArray *result, BOOL haveMoreData))success
					failure:(void(^)())failure
{
	[commentRep invokeStaticMethod:@"commentsByClip"
						parameters:@{@"id_clip":clipID, @"limit": [NSNumber numberWithInteger:pageSize], @"skip": [NSNumber numberWithInteger:offset]}
						   success:^(id value) {
							   
							   NSArray *list = (NSArray*)[[value objectForKey:@"data"] objectForKey:@"commentsList"];
							   
							   BOOL hasMore = true;
							   
							   if(list.count < pageSize) {
								   hasMore = false;
							   }
							   
							   success([self generateCommentObjsWith:list hasMore:hasMore], hasMore);
						   }
						   failure:^(NSError *error) {
							   failure();
						   }];
}

- (NSArray *)generateCommentObjsWith:(NSArray *)list hasMore:(BOOL)hasMore{
	NSMutableArray* comments = [[NSMutableArray alloc] init];
	for(NSDictionary *dict in list) {
		ModelComment *comment = [ModelComment commentWithProperties:dict];
		[comments addObject:comment];
	}
	if(hasMore) {
		[comments removeLastObject];
	}
	return [comments copy];
}

- (void)getCommentsSummaryByPostID:(NSString *)postID
						 isRefresh:(BOOL)isRefresh
						   success:(void(^)(NSArray*)) success
						   failure:(void(^)())failure
{
	[postRep invokeStaticMethod:@"getCommentQty"
					 parameters:@{
								  @"id_post": postID,
								  @"isRefresh":[NSNumber numberWithBool:isRefresh]
								}
						success:^(id value) {
							success([[value objectForKey:@"data"] objectForKey:@"commentQtyList"]);
						}
						failure:^(NSError *error) {
							failure();
						}];
}

- (void)getCommentsSummaryByClipIDs:(NSArray *)clips
						  isRefresh:(BOOL)isRefresh
							success:(void(^)(NSArray*))success
							failure:(void(^)())failure
{	
	[postRep invokeStaticMethod:@"getCommentQtyByClips"
					 parameters:@{
								  @"clips": clips,
								  @"isRefresh":[NSNumber numberWithBool:isRefresh]
								}
						success:^(id value) {
							success([[value objectForKey:@"data"] objectForKey:@"commentQtyList"]);
						}
						failure:^(NSError *error) {
							failure();
						}];
}


- (void)commentWithClipID:(NSString *)clipID
				 withText:(NSString *)text
{
	[self.commentdelegate willPerformAction];
	
	newCommentClipID = clipID;
	newCommentText = text;
	
	if([user.commentAccountID isEqual:@""]) {
		[self socialButtonsForShare:NO];
	}else {
		[self performComment];
	}
}

- (void)shareWithClipID:(NSURL *)clipID {
	sharedClipID = clipID;
	[self showComposeViewWithText];
}

- (void)recordFavoriteWithClipID:(NSString *)url
					   postID:(NSString *)postID {
	if(postID == nil) {
		postID = @"Album";
	}
	[visitRep invokeStaticMethod:@"recordFavorite"
					  parameters:@{@"id_clip": url,
								   @"id_post": postID
								 }
						 success:^(id value) {
						 }
						 failure:^(NSError *error) {
						 }
	];
}

- (void)recordSlowPlayWithClipID:(NSString *)url {
	[visitRep invokeStaticMethod:@"recordSlowPlay"
					  parameters:@{@"id_clip": url}
						 success:^(id value) {
						 }
						 failure:^(NSError *error) {
						 }
	];
}

- (void)recordAppStart {
	[visitRep invokeStaticMethod:@"recordAppStart"
					  parameters:nil
						 success:^(id value) {
						 }
						 failure:^(NSError *error) {
							 if([self lbErrorCodeWith: error] == UserNotLoggedIn) {
								 adapter.accessToken = nil;
//								 [self registerDeviceWithSuccess:nil failure:nil];
							 }
						 }
	];
}

- (void)recordAppInstall {
	[visitRep invokeStaticMethod:@"recordAppInstall"
					  parameters:@{@"appInfo": [self appNameAndVersionNumberDisplayString]}
						 success:^(id value) {
						 }
						 failure:^(NSError *error) {
						 }
	 ];
}

- (void)fetchClipsFromURL:(NSString *)url
				  success:(void(^)(NSArray*, NSString*))success
				  failure:(void(^)())failure
{
	[apiRep invokeStaticMethod:@"getImageFromWebpage"
					  parameters:@{@"url": url}
						 success:^(id value) {
							 id object = [value objectForKey:@"data"];
							 success([object objectForKey:@"imageList"], [object objectForKey:@"title"]);
						 }
						 failure:^(NSError *error) {
							 failure();
						 }
	 ];
}


#pragma mark - Share buttons View
- (void)socialButtonsForShare:(BOOL)forShare{
	if(shareBubbles) {
		shareBubbles = nil;
	}

	shareBubbles = [[AAShareBubbles alloc] initCenteredInWindowWithRadius:100];
	
	shareBubbles.delegate = self;
	shareBubbles.bubbleRadius = 40;
	shareBubbles.showSinaWeiboBubble = YES;
	if(!forShare) {
		shareBubbles.showQQBubble = YES;
	}
	
//	shareBubbles.showQzoneBubble = YES;
//	shareBubbles.showFacebookBubble = YES;
//	shareBubbles.showTwitterBubble = YES;
//	shareBubbles.showGooglePlusBubble = YES;
//	shareBubbles.showTumblrBubble = YES;
//	shareBubbles.showVkBubble = YES;
//	shareBubbles.showLinkedInBubble = YES;
//	shareBubbles.showYoutubeBubble = YES;
//	shareBubbles.showVimeoBubble = YES;
//	shareBubbles.showRedditBubble = YES;
//	shareBubbles.showPinterestBubble = YES;
//	shareBubbles.showInstagramBubble = YES;
//	shareBubbles.showWhatsappBubble = YES;
	
//	FAKFontAwesome *weiboIcon = [FAKFontAwesome weiboIconWithSize:50];
//	
//	FAKFontAwesome *qqIcon = [FAKFontAwesome qqIconWithSize:50];
//	
//	[weiboIcon addAttribute:NSForegroundColorAttributeName value:[UIColor
//																 whiteColor]];
//	
//	[qqIcon addAttribute:NSForegroundColorAttributeName value:[UIColor
//																 whiteColor]];
//	
//	
//	[shareBubbles addCustomButtonWithIcon:[weiboIcon imageWithSize:CGSizeMake(50, 50)]
//						  backgroundColor:[UIColor colorWithRed:193.0/255.0 green:27.0/255.0 blue:23.0/255.0 alpha:1.0]
//							  andButtonId:WEIBO_BUTTON_ID];
//	
//	[shareBubbles addCustomButtonWithIcon:[qqIcon imageWithSize:CGSizeMake(50, 50)]
//						  backgroundColor:[UIColor colorWithRed:59.0/255.0 green:185.0/255.0 blue:255.0/255.0 alpha:1.0]
//							  andButtonId:QQ_BUTTON_ID];
	
	[shareBubbles show];
	
	if([self isCommenting]) {
		[self.commentdelegate didShowLoginSelection];
	}
	
	if([self isSharing]) {
//		[self.shareDelegate didShowLoginSelection];
		[self hideProgressView];
	}
}

-(void)aaShareBubbles:(AAShareBubbles *)shareBubbles tappedBubbleWithType:(AAShareBubbleType)bubbleType
{
	switch (bubbleType) {
		case AAShareBubbleTypeSinaWeibo:
			[self loginWeibo];
			break;
		case AAShareBubbleTypeQQ:
			[self login];
			break;
		default:
			break;
	}
}

-(void)aaShareBubblesDidHide:(AAShareBubbles *)bubbles {
	if(bubbles.viewBackgroundTapped == YES){
		[self failureWithErroCode:LoginCancelled];
	}
}

#pragma mark - Progress View

- (void)showProgressViewWithText:(NSString *)text {
	[self progressViewWithText:text withAnimation:YES];
}

- (void)showProgressView {
	[self progressViewWithText:@"Sending..." withAnimation:YES];
}

- (void)hideProgressView {
	[progressView dismiss:NO];
	progressView = nil;
}

- (void)showProgressViewWithNoLabel {
	if(progressView != nil) {
		progressView = nil;
	}
	progressView = [self progressViewWithText:@"" withAnimation:YES andMode:MRProgressOverlayViewModeIndeterminateSmallDefault];
}

- (void)progressViewWithText:(NSString *)text withAnimation:(BOOL)animatted {
	
	if(progressView != nil) {
		progressView = nil;
	}
	
	progressView = [self progressViewWithText:text withAnimation:animatted andMode:MRProgressOverlayViewModeIndeterminateSmall];
}

- (MRProgressOverlayView *)progressViewWithText:(NSString *)text withAnimation:(BOOL)animatted andMode:(MRProgressOverlayViewMode)mode
{
	MRProgressOverlayView *view = [MRProgressOverlayView showOverlayAddedTo:[UIApplication sharedApplication].keyWindow animated:animatted];
	
	view.mode = mode;
	
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(text, nil) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18], NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
	
	view.titleLabelAttributedText = title;
	
	view.tintColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	
	return view;
}

#pragma mark - Comment
- (void)performComment {
	
	if(newCommentClipID == nil || newCommentText == nil) return;
	
	LBPersistedModel *model = (LBPersistedModel*)[commentRep modelWithDictionary:@{@"id_clip":newCommentClipID,@"text":newCommentText,@"id_account":user.commentAccountID}];
	
	[model saveWithSuccess:^(id value){
		[self commentSuccess:value];
	} failure:^(NSError *error) {
		switch ([self lbErrorCodeWith: error]) {
			case UserNotLoggedIn:
				[self socialButtonsForShare:NO];
				break;
			case UserDisabled:
				[self commentfailure:UserDisabled];
				break;
			case CommentExceedLimit:
				[self commentfailure:CommentExceedLimit];
				break;
			default:
				[self commentfailure:ServerError];
				break;
		}
	}];
}

- (ModelComment *)generateCommentModel:(NSDictionary *)value{
	NSMutableDictionary *commentInfo = [value mutableCopy];
	[commentInfo setObject:@{
						@"name": user.commentName,
						@"avatar": user.commentAvatar
					  }
			 forKey:@"author"];
	return [ModelComment commentWithProperties:[commentInfo copy]];
}

- (void)commentSuccess:(id)value {
	[self.commentdelegate didPerformActionWithResult:[self generateCommentModel:[value objectForKey:@"data"]] error:NO];
	newCommentClipID = nil;
	newCommentText = nil;
}

- (void)commentfailure:(NSInteger)code {
	[self failureWithErroCode:code];
	newCommentClipID = nil;
	newCommentText = nil;
}


#pragma mark - Share

- (void)tryShare
{
//	[self.shareDelegate willPerformAction];
	
	[self showProgressView];
	
//	if(user.wbRefreshToken == nil || user.wbAccessToken == nil) {
	if([user.shareAccountID isEqual:@""]) {
//		[self.shareDelegate didShowLoginSelection];
		[self hideProgressView];
		[self loginWeibo];
	}else{
		[WBHttpRequest requestForRenewAccessTokenWithRefreshToken:user.shareWBRefreshToken queue:nil withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
			
			if(error == nil) {
				[self performShare];
			}else if(error.code && error.code >= 21300 && error.code <= 21399){
//				[self.shareDelegate didShowLoginSelection];
				[self hideProgressView];
				[self loginWeibo];
			}else{
				[self failureWithErroCode:ServerError];
			}
		}];
	}
}

- (void)performShare
{
	if(sharedClipID == nil) return;
	
	[visitRep invokeStaticMethod:@"shareClip"
					  parameters:@{@"id_clip": [sharedClipID absoluteString],
								   @"id_account": user.shareAccountID
								 }
						 success:^(id value) {
							 [[YYImageCache sharedCache] getImageDataForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:sharedClipID] withBlock:^(NSData * _Nullable imageData) {
								 
								 WBImageObject *image = [WBImageObject object];
								 image.imageData = imageData;
								 
								 NSString *fromText = NSLocalizedString(@"This NBA GIF is shared from Cliplay APP", @"Post text");
								 
								 NSString *textToSend = (sharedText == nil || [sharedText isEqual: @""])? fromText: [NSString stringWithFormat:@"%@ -- %@", sharedText, fromText];
								 
								 [WBHttpRequest requestForShareAStatus:textToSend
													 contatinsAPicture:image
														  orPictureUrl:nil
													   withAccessToken:user.shareWBAccessToken
													andOtherProperties:nil
																 queue:nil
												 withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
													 if(error == nil) {
														 [self shareSuccess];
													 }else {
														 [self shareFailure:ServerError];
													 }
												 }
								  ];
							 }];
						 }
						 failure:^(NSError *error) {
							 switch ([self lbErrorCodeWith: error]) {
								 case UserNotLoggedIn:
									 [self hideProgressView];
									 [self loginWeibo];
									 break;
								 case UserDisabled:
									 [self shareFailure:UserDisabled];
									 break;
								 case ShareExceedLimit:
									 [self shareFailure:ShareExceedLimit];
									 break;
								 default:
									 [self shareFailure:ServerError];
									 break;
							 }
						 }
	 ];
	
//	[self shareClipWithClipID:[sharedClipID absoluteString] success:^() {
//		
//		[[YYImageCache sharedCache] getImageDataForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:sharedClipID] withBlock:^(NSData * _Nullable imageData) {
//			
//			WBImageObject *image = [WBImageObject object];
//			image.imageData = imageData;
//			
//			NSString *fromText = NSLocalizedString(@"This NBA GIF is shared from Cliplay APP", @"Post text");
//			
//			NSString *textToSend = (sharedText == nil || [sharedText isEqual: @""])? fromText: [NSString stringWithFormat:@"%@ -- %@", sharedText, fromText];
//			
//			[WBHttpRequest requestForShareAStatus:textToSend
//								contatinsAPicture:image
//									 orPictureUrl:nil
//								  withAccessToken:shareUser.wbAccessToken
//							   andOtherProperties:nil
//											queue:nil
//							withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
//								if(error == nil) {
//									[self shareSuccess];
//								}else {
//									[self shareFailure:ServerError];
//								}
//							}
//			 ];
//		}];
//	} failure:^(NSError *error){
//		switch ([self lbErrorCodeWith: error]) {
//			case UserNotLoggedIn:
//				[self hideProgressView];
//				[self loginWeibo];
//				break;
//			case UserDisabled:
//				[self shareFailure:UserDisabled];
//				break;
//			case ShareExceedLimit:
//				[self shareFailure:ShareExceedLimit];
//				break;
//			default:
//				[self shareFailure:ServerError];
//				break;
//		}
//	}];
}

- (void)shareSuccess {
//	[self.shareDelegate didPerformActionWithResult:nil error:NO];
	[self shareCompletesWith:nil error:NO];;
	sharedClipID = nil;
	sharedText = nil;
}

- (void)shareFailure:(NSInteger)code {
	[self failureWithErroCode:code];
//	sharedClipID = nil;
//	sharedText = nil;
}

- (void)shareCancelled {
	sharedClipID = nil;
	sharedText = nil;
}

//- (void)shareClipWithClipID:(NSString *)clipID
//					success:(void(^)())success
//					failure:(void(^)(NSError *error))failure
//{
//	[visitRep invokeStaticMethod:@"shareClip"
//					 parameters:@{@"id_clip": clipID}
//						success:^(id value) {
//							success();
//						}
//						failure:^(NSError *error) {
//							failure(error);
//						}
//	 ];
//}

- (void)showComposeViewWithText {
	[[YYImageCache sharedCache] getImageForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:sharedClipID] withType:YYImageCacheTypeAll withBlock:^(UIImage * _Nullable image, YYImageCacheType type) {
		
		if(composeView != nil) composeView = nil;
		
		composeView = [[REComposeViewController alloc] init];
		composeView.title = @"分享到新浪微博";
		composeView.hasAttachment = YES;
		composeView.delegate = self;
		composeView.attachmentImage = image;
		composeView.text = sharedText? sharedText: @"";
		[composeView presentFromRootViewController];
	}];
}

- (void)composeViewController:(REComposeViewController *)composeViewController didFinishWithResult:(REComposeResult)result
{
	[composeView dismissViewControllerAnimated:YES completion:nil];
	
	if (result == REComposeResultCancelled) {
		[self shareCancelled];
	}
	
	if (result == REComposeResultPosted) {
		sharedText = composeViewController.text;
		[self tryShare];
	}
}

- (void)redisplayComposeView {
	if([self isSharing]) {
		
		[self performSelector:@selector(showComposeViewWithText) withObject:nil afterDelay:0.6];
		//			[self performBlock:^{
		//				[self showComposeViewWithText];
		//			} afterDelay:0.6];
	}
}

//- (void)willPerformAction {
//	[self showProgressView:YES];
//}

//- (void)didShowLoginSelection{
//	[progressView dismiss:NO];
//}
//- (void)didSelectLogin {
//	[self showProgressView];
//}

- (void)shareCompletesWith:(id)result error:(BOOL)error{
	[progressView dismiss:NO completion:^{
		if(!error){
			MRProgressOverlayView *resultView = [self progressViewWithText:@"Succeed" withAnimation:NO andMode:MRProgressOverlayViewModeCheckmark];
			
			[self performBlock:^{
				[resultView dismiss:YES];
			} afterDelay:0.8];
		}
	}];
}

//
//- (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
//	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
//	dispatch_after(popTime, dispatch_get_main_queue(), block);
//}

#pragma mark - Tencent
- (void)login {
	NSArray* permissions = [NSArray arrayWithObjects:
							kOPEN_PERMISSION_GET_USER_INFO,
							kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
							kOPEN_PERMISSION_ADD_ALBUM,
							kOPEN_PERMISSION_ADD_ONE_BLOG,
							kOPEN_PERMISSION_ADD_SHARE,
							kOPEN_PERMISSION_ADD_TOPIC,
							kOPEN_PERMISSION_CHECK_PAGE_FANS,
							kOPEN_PERMISSION_GET_INFO,
							kOPEN_PERMISSION_GET_OTHER_INFO,
							kOPEN_PERMISSION_LIST_ALBUM,
							kOPEN_PERMISSION_UPLOAD_PIC,
							kOPEN_PERMISSION_GET_VIP_INFO,
							kOPEN_PERMISSION_GET_VIP_RICH_INFO,
							nil];
	
	[oauth authorize:permissions inSafari:NO];
}

// 登录成功后的回调
- (void)tencentDidLogin {
	
	if (oauth.accessToken && 0 != [oauth.accessToken length])
	{
		if([self isCommenting]) {
			[self.commentdelegate didSelectLogin];
		}
		
		if([self isSharing]) {
//			[self.shareDelegate didSelectLogin];
			[self showProgressView];
		}
		[oauth getUserInfo];
	}
}

- (void)getUserInfoResponse:(APIResponse*) response {
	if (URLREQUEST_SUCCEED == response.retCode
		&& kOpenSDKErrorSuccess == response.detailRetCode) {
		
		[self registerAccountWith:@"qq"
						   userID:oauth.openId
						 userName:[response.jsonResponse objectForKey:@"nickname"]
						   avatar:[response.jsonResponse objectForKey:@"figureurl_qq_2"]
					wbAccessToken:@""
				   wbRefreshToken:@""
		];
		
	} else {
		[self failureWithErroCode:ServerError];
	}
}

// 登录失败后的回调
- (void)tencentDidNotLogin:(BOOL)cancelled {
	if (cancelled) {
		[self failureWithErroCode:LoginCancelled];
	}else {
		[self failureWithErroCode:ServerError];
	}
}

// 登录时网络有问题的回调
- (void)tencentDidNotNetWork{
	[self failureWithErroCode:ServerError];
}


- (void)registerAccountWith:(NSString *)platform
					 userID:(NSString *)userID
				   userName:(NSString *)name
					 avatar:(NSString *)avatar
			  wbAccessToken:(NSString *)wbAccessToken
			 wbRefreshToken:(NSString *)wbRefreshToken
{
	BOOL isCommenting = [self isCommenting];
	[clientRep invokeStaticMethod:@"addAccount"
					   parameters:@{
									@"type":isCommenting?@"comment":@"share",
									@"platform":platform,
									@"openID":userID,
									@"name":name,
									@"avatar":avatar
									}
						  success:^(id value) {
							  
							  NSString *accountID = [[value objectForKey:@"data"] objectForKey:@"accountID"];
							  
							  if(isCommenting) {
								  user.commentAccountID = accountID;
								  user.commentName = name;
								  user.commentAvatar = avatar;
								  [user save];
								  
								  [self performComment];
							  }else{
								  user.shareAccountID = accountID;
								  user.shareWBAccessToken = wbAccessToken;
								  user.shareWBRefreshToken = wbRefreshToken;
								  [user save];
								  
								  [self performShare];
							  }
						  }
						  failure:^(NSError *error) {
//							  if([self lbErrorCodeWith: error] == UserNotLoggedIn) {
//								  [self registerDeviceWithSuccess:^{
//									  [self registerAccountWith:platform
//														 userID:userID
//													   userName:name
//														 avatar:avatar
//												  wbAccessToken:wbAccessToken
//												 wbRefreshToken:wbRefreshToken
//									   ];
//								  } failure:^{
//									  [self commentfailure:ServerError];
//								  }];
//							  }else{
//								  [self commentfailure:ServerError];
//							  }
							  if([self lbErrorCodeWith: error] == UserNotLoggedIn) {
								  [self registerDeviceWithSuccess:nil failure:nil];
							  }
							  [self commentfailure:ServerError];
						}
	];
}

#pragma mark - Weibo

- (void)loginWeibo {
	WBAuthorizeRequest *request = [WBAuthorizeRequest request];
	request.redirectURI = kRedirectURI;
	request.scope = @"all";
	[WeiboSDK sendRequest:request];
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
	
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
	if ([response isKindOfClass:WBAuthorizeResponse.class])
	{
		if([self isCommenting]) {
			[self.commentdelegate didSelectLogin];
		}
		
		if([self isSharing]) {
//			[self.shareDelegate didSelectLogin];
			[self showProgressView];
		}
		
		if(((WBAuthorizeResponse *)response).statusCode ==WeiboSDKResponseStatusCodeUserCancel) {
			[self failureWithErroCode:LoginCancelled];
		}else {
			NSString *userID = [(WBAuthorizeResponse *)response userID];
			NSString *accessToken = [(WBAuthorizeResponse *)response accessToken];
			NSString *wbRefreshToken = [(WBAuthorizeResponse *)response refreshToken];
			
			[WBHttpRequest requestForUserProfile:userID withAccessToken:accessToken andOtherProperties:nil queue:nil withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
				
				[self weiboUserProfileRequestHanlder:httpRequest result:result error:error accessToken:accessToken refreshToken:wbRefreshToken];
			}];
		}
	}
}

- (void)weiboUserProfileRequestHanlder:(WBHttpRequest *)httpRequest
								result:(id)result
								 error:(NSError *)error
						   accessToken:(NSString *)accessToken
						  refreshToken:(NSString *)refreshToken
{
	if (error)
	{
		[self failureWithErroCode:ServerError];
	}
	else
	{
		NSString *userID = ((WeiboUser *)result).userID;
		NSString *screenName = ((WeiboUser *)result).screenName;
		NSString *image = ((WeiboUser *)result).profileImageUrl;
		
		[self registerAccountWith:@"weibo"
						   userID:userID
						 userName:screenName
						   avatar:image
					wbAccessToken:accessToken
				   wbRefreshToken:refreshToken
		];
	}
}

//- (WBMessageObject *)messageToShare:(NSData *)data
//{
//	WBMessageObject *message = [WBMessageObject message];
//	
//	WBImageObject *image = [WBImageObject object];
//	image.imageData = data;
//	message.imageObject = image;
//	
//	return message;
//}

#pragma mark - Util
- (BOOL)isCommenting {
	return (newCommentText && newCommentClipID)? YES: NO;
}

- (BOOL)isSharing {
	return sharedClipID? YES: NO;
}

- (void)failureWithErroCode:(NSInteger)code {
	
	if([self isCommenting]) {
		[self.commentdelegate didPerformActionWithResult:nil error:YES];
	}
	
	if([self isSharing]) {
//		[self.shareDelegate didPerformActionWithResult:nil error:YES];
		[self shareCompletesWith:nil error:YES];
	}
	
	NSString *reason;
	
	switch (code) {
		case ServerError:
			reason = NSLocalizedString(@"User login error, please try again later", @"maybe network error");
			break;
		case LoginCancelled:
			reason = NSLocalizedString(@"You're not allowed to comment because you cancelled login", @"User cancelled login");
			break;
		case ShareExceedLimit:
			reason = NSLocalizedString(@"You're exceeding share limit per day", @"User cancelled login");
			break;
		case UserDisabled:
			reason = NSLocalizedString(@"You're not allowed to function", @"User disabled");
			break;
		case CommentExceedLimit:
			reason = NSLocalizedString(@"You comment too often", @"Exceed comment limit");
			break;
		default:
			reason = NSLocalizedString(@"Some errors, please try again later", @"Unknown error");
			break;
	}
	
	[self performSelector:@selector(showAlertView:) withObject:reason afterDelay:0.6];
}

-(NSInteger)lbErrorCodeWith:(NSError *)error {
	@try {
		NSString *msg = error.localizedRecoverySuggestion;
		
		NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding: NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
		
		return [(NSNumber *)[[dict objectForKey:@"error"] objectForKey:@"status"] integerValue];
	}
	@catch (NSException *exception) {
		return 400;
	}
}

- (void)showAlertView:(NSString *)reason {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"操作失败" message:reason delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil];
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
//		[self redisplayComposeView];
	}
}

- (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

- (BOOL)handleOpenURL:(NSURL *)url {
	if ([[url scheme] isEqualToString:weibo_SCHEME])
		return [WeiboSDK handleOpenURL:url delegate:self];
	
	if ([[url scheme] isEqualToString:tencent_SCHEME])
		return [TencentOAuth HandleOpenURL:url];
	
	return true;
}

- (NSString *)appNameAndVersionNumberDisplayString {
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
	NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
	NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
	
	return [NSString stringWithFormat:@"%@, Version %@ (%@)",
			appDisplayName, majorVersion, minorVersion];
}

@end

#pragma mark - Override model base save function
@implementation LBPersistedModel (Cliplay)

- (void)saveWithSuccess:(MyLBPersistedModelSaveSuccessBlock)success
				failure:(SLFailureBlock)failure {
	[self invokeMethod:self._id ? @"save" : @"create"
			parameters:self._id ? @{ @"id": self._id } : nil
		bodyParameters:[self toDictionary]
			   success:^(id value) {
				   success(value);
			   }
			   failure:failure];
}

@end
