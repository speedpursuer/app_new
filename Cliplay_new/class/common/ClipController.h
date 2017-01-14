//
//  ClipController.h
//  YYKitExample
//
//  Created by ibireme on 15/7/19.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNPPopupController.h"
#import "CacheManager.h"
#import "EBCommentsViewDelegate.h"
#import "DOFavoriteButton.h"
#import "MyLBDelegate.h"
#import "Album.h"
#import "News.h"

typedef NS_ENUM(NSInteger, clipActionType) {
	addToAlbum,
	addAllToAlbum,
	editClip,
	modifyDesc,
	deleteClip,
	noAction,
};

//@interface ClipController : UITableViewController <UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, CNPPopupControllerDelegate>
@interface ClipController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, CNPPopupControllerDelegate,UITableViewDelegate, UITableViewDataSource, DownloadDelegate>

@property (nonatomic, strong) NSArray *articleDicts;
@property (nonatomic, strong) NSArray *articleURLs;
@property (nonatomic, strong) Album *album;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) NSString *header;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, assign) BOOL showInfo;
@property (nonatomic, strong) NSString *postID;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) BOOL fetchMode;
@property (strong) DOFavoriteButton *infoButton;
//@property (nonatomic, assign) BOOL fullScreen;

- (void)popupControllerDidDismiss:(CNPPopupController *)controller;
- (NSString *)getCommentQty:(NSString *)clipID;
- (void)showComments:(NSString *)clipID;
- (void)shareClip:(NSURL *)clipID;
- (BOOL)isFullyVisible:(UITableViewCell *)cell;
- (BOOL)needToPlay:(UITableViewCell *)cell;
- (void)setFavoriate:(NSString *)url;
- (void)unsetFavoriate:(NSString *)url;
- (BOOL)isFavoriate:(NSString *)url;
- (void)recordSlowPlayWithUrl:(NSString *)url;
- (void)formActionForCell:(UITableViewCell *)cell withActionType:(clipActionType)type;
- (BOOL)isCollected:(NSString *)url;
- (void)helloFromCell:(UITableViewCell *)cell;
#pragma mark - Callback for comment view
- (void)fetchPostComments:(BOOL)isRefresh;
- (void)clipDescCallbackWithDesc:(NSString *)desc;
- (void)albumInfoCallbackWithName:(NSString *)name withDesc:(NSString *)desc;
//- (void)closeCommentView;
@end
