//
//  ClipCell.h
//  Cliplay
//
//  Created by 邢磊 on 16/8/18.
//
//

#import <Foundation/Foundation.h>
#import "UIView+YYAdd.h"
#import "CALayer+YYAdd.h"
#import "UIGestureRecognizer+YYAdd.h"
#import "DOFavoriteButton.h"
#import "TTTAttributedLabel.h"
#import "VoteView.h"
#import "ClipControllerNew.h"

#define TitleCellIdentifier @"titleCell"
#define ClipCellIdentifier  @"clipCell"
#define AlbumCellIdentifier @"albumCell"

@interface ClipCellNew : UITableViewCell
@property (nonatomic, strong) YYAnimatedImageView *webImageView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *errLabel;
@property (nonatomic, assign) BOOL downLoaded;
@property (nonatomic, strong) DOFavoriteButton *heartButton;
@property (nonatomic, strong) UIButton *commentBtn;
@property (nonatomic, strong) UIButton *shareBtn;
@property (nonatomic, strong) DOFavoriteButton *albumBtn;
@property (nonatomic, weak) ClipControllerNew *delegate;
@property (nonatomic, assign) CGFloat cellHeight;
- (void)setCellData:(ImageEntity*) entity isForHeight:(BOOL)isForHeight;
- (void)updateCommentQty;
- (void)setBorder;
- (void)unSetBorder;
- (void)selectAlbumButton;
@end

@interface TitleCellNew : UITableViewCell
@property (nonatomic, strong) TTTAttributedLabel *imageLabel;
@property VoteView *voteView;
- (void)setCellData:(ImageEntity*) entity isForHeight:(BOOL)isForHeight;
@end
