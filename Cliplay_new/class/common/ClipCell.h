//
//  ClipCell.h
//  Cliplay
//
//  Created by 邢磊 on 16/8/18.
//
//

#import <Foundation/Foundation.h>
#import <YYWebImage/YYWebImage.h>
#import "UIView+YYAdd.h"
#import "CALayer+YYAdd.h"
#import "UIGestureRecognizer+YYAdd.h"
#import "DOFavoriteButton.h"
#import "TTTAttributedLabel.h"
#import "ArticleEntity.h"
#import "ClipController.h"

#define TitleCellIdentifier @"titleCell"
#define ClipCellIdentifier  @"clipCell"
#define AlbumCellIdentifier @"albumCell"

@interface ClipCell : UITableViewCell
@property (nonatomic, strong) YYAnimatedImageView *webImageView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *errLabel;
@property (nonatomic, assign) BOOL downLoaded;
@property (nonatomic, strong) DOFavoriteButton *heartButton;
@property (nonatomic, strong) UIButton *commentBtn;
@property (nonatomic, strong) UIButton *shareBtn;
@property (nonatomic, strong) DOFavoriteButton *albumBtn;
//@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, weak) ClipController *delegate;
@property (nonatomic, assign) CGFloat cellHeight;
- (void)setCellData:(ArticleEntity*) entity isForHeight:(BOOL)isForHeight;
- (void)updateCommentQty;
- (void)setBorder;
- (void)unSetBorder;
- (void)selectAlbumButton;
@end

@interface TitleCell : UITableViewCell
@property (nonatomic, strong) TTTAttributedLabel *imageLabel;
- (void)setCellData:(ArticleEntity*) entity isForHeight:(BOOL)isForHeight;
@end
