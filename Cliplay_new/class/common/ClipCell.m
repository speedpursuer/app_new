//
//  ClipCell.m
//  Cliplay
//
//  Created by 邢磊 on 16/8/18.
//
//

#import "ClipCell.h"
#import "ClipPlayController.h"
#import "DRImagePlaceholderHelper.h"
#import <FontAwesomeKit/FAKFontAwesome.h>

#define cellMargin 10
//#define kCellHeight ceil((kScreenWidth) * 10.0 / 16.0)
#define kScreenWidth ((UIWindow *)[UIApplication sharedApplication].windows.firstObject).width - cellMargin * 2
#define sHeight [UIScreen mainScreen].bounds.size.height


@implementation TitleCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	self.backgroundColor = [UIColor whiteColor];
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.contentView.bounds = [UIScreen mainScreen].bounds;
	self.size = CGSizeMake(kScreenWidth, 0);
	self.contentView.size = self.size;
	
	_imageLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
	_imageLabel = [TTTAttributedLabel new];
	_imageLabel.textAlignment = NSTextAlignmentLeft;
	_imageLabel.numberOfLines = 0;
	[_imageLabel setTextColor:[UIColor darkGrayColor]];
	[self.contentView addSubview:_imageLabel];
	
	return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(kScreenWidth, self.imageLabel.size.height + cellMargin * 2);
}

- (void)setCellData:(ArticleEntity*) entity isForHeight:(BOOL)isForHeight {
	
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.lineSpacing = 10;
	style.paragraphSpacing = 11;
	
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:entity.desc
																	attributes:@{
																				 (id)kCTForegroundColorAttributeName : (id)[UIColor darkGrayColor].CGColor,
																				 NSFontAttributeName : [UIFont systemFontOfSize:16],
																				 (id)kCTParagraphStyleAttributeName : style,
																				 }];
	
	self.imageLabel.text = attString;
	self.imageLabel.frame = CGRectMake(cellMargin, cellMargin, kScreenWidth, 0);
	[self.imageLabel sizeToFit];
}
@end

@implementation ClipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	self.backgroundColor = [UIColor whiteColor];
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.contentView.bounds = [UIScreen mainScreen].bounds;
	self.size = CGSizeMake(kScreenWidth, 0);
	self.contentView.size = self.size;
	
	_webImageView = [YYAnimatedImageView new];
	_webImageView.size = self.size;
	_webImageView.left = cellMargin;
	_webImageView.clipsToBounds = YES;
	_webImageView.contentMode = UIViewContentModeScaleAspectFill;
	_webImageView.backgroundColor = [UIColor lightGrayColor];
	[self.contentView addSubview:_webImageView];
	
	_progressLayer = [CAShapeLayer layer];
	_progressLayer.strokeColor = [UIColor whiteColor].CGColor;
	_progressLayer.lineCap = kCALineCapButt;
	_progressLayer.strokeStart = 0;
	_progressLayer.strokeEnd = 0;
	[_webImageView.layer addSublayer:_progressLayer];
	
	_label = [UILabel new];
	_label.textAlignment = NSTextAlignmentCenter;
	_label.text = @"球    路";
	_label.textColor = [UIColor lightGrayColor];
	_label.font = [UIFont systemFontOfSize:50];	
	[self.contentView addSubview:_label];
	
	_errLabel = [UILabel new];
	_errLabel.textAlignment = NSTextAlignmentCenter;
	_errLabel.text = @"下载异常, 点击重试";
	_errLabel.textColor = [UIColor whiteColor];
	_errLabel.userInteractionEnabled = YES;
	_errLabel.font = [UIFont systemFontOfSize:20];
	[self.contentView addSubview:_errLabel];
	__weak typeof(self) _self = self;
	UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
		[_self setImageURL:_self.webImageView.yy_imageURL];
	}];
	[_errLabel addGestureRecognizer:g];
	_heartButton = [self createFlashButtonWithImage:[UIImage imageNamed:@"heart"]];
	[_heartButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
	_heartButton.top = _webImageView.top;
	_heartButton.left = _webImageView.left;
	[self.contentView addSubview:_heartButton];
	
	UIImage* commentsImage = [self createCommentIconWithCount: -1];
	_commentBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	_commentBtn.frame = CGRectMake(0, 0, 45, 45);
	[_commentBtn setImage:commentsImage forState:UIControlStateNormal];
	[_commentBtn setImage:commentsImage forState:UIControlStateHighlighted];
	[_commentBtn setTintColor:[UIColor colorWithRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.6]];
	_commentBtn.top = _webImageView.top;
	_commentBtn.right = _webImageView.right;
	[self.contentView addSubview:_commentBtn];
	[_commentBtn addTarget:self action:@selector(displayComment) forControlEvents:UIControlEventTouchUpInside];
	
	FAKFontAwesome *shareIcon = [FAKFontAwesome weiboIconWithSize:20];
	UIImage *shareImage = [shareIcon imageWithSize:CGSizeMake(20, 20)];
	_shareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	_shareBtn.frame = CGRectMake(0, 0, 40, 40);
	[_shareBtn setImage:shareImage forState:UIControlStateNormal];
	[_shareBtn setImage:shareImage forState:UIControlStateHighlighted];
	[_shareBtn setTintColor:[UIColor colorWithRed:255.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.6]];
	[self.contentView addSubview:_shareBtn];
	[_shareBtn addTarget:self action:@selector(shareClip) forControlEvents:UIControlEventTouchUpInside];
	
	[self setupAlbumIcon:reuseIdentifier];
	
	[_self addClickControlToAnimatedImageView];
	
	return self;
}

- (DOFavoriteButton *)createFlashButtonWithImage:(UIImage *)image{
	DOFavoriteButton *button = [[DOFavoriteButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40) image:image selected: false];
	button.imageColorOn = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	button.circleColor = [UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	button.lineColor = [UIColor colorWithRed:245.0 / 255.0 green:54.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
	return button;
}

- (void)setupAlbumIcon:(NSString *)reuseIdentifier {
	FAKFontAwesome *albumIcon;
	
	if([reuseIdentifier isEqualToString:AlbumCellIdentifier]) {
		albumIcon = [FAKFontAwesome editIconWithSize:20];
	}else{
		albumIcon = [FAKFontAwesome folderOpenIconWithSize:20];
	}
	
	UIImage *albumImage = [albumIcon imageWithSize:CGSizeMake(20, 20)];
	_albumBtn = [self createFlashButtonWithImage:albumImage];
	[self.contentView addSubview:_albumBtn];
	
	if([reuseIdentifier isEqualToString:AlbumCellIdentifier]) {
		[_albumBtn addTarget:self action:@selector(editClipInAlbum) forControlEvents:UIControlEventTouchUpInside];
	}else{
		[_albumBtn addTarget:self action:@selector(collectClipToAlbum) forControlEvents:UIControlEventTouchUpInside];
	}
}

- (void)tappedButton:(DOFavoriteButton *)sender {
	ClipController* ctr = [self getViewCtr];
	if (sender.selected) {
		[sender deselect];
		[ctr unsetFavoriate:[[_webImageView yy_imageURL] absoluteString]];
	} else {
		[sender select];
		[ctr setFavoriate:[[_webImageView yy_imageURL] absoluteString]];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGFloat totalHeight = 0;
	totalHeight += self.webImageView.size.height;
	totalHeight += cellMargin;
	return CGSizeMake(kScreenWidth, totalHeight);
}


- (void)addClickControlToAnimatedImageView{
	
	self.webImageView.userInteractionEnabled = YES;
	
	__weak typeof(self.webImageView) _view = self.webImageView;
	__weak typeof(self) _self = self;
	
	UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
		
		if(!_self.downLoaded) return;
		
		[_self showClipView:[[_view yy_imageURL] absoluteString]];
	}];
	
	doubleTap.numberOfTapsRequired = 1;
	
	[_view addGestureRecognizer:doubleTap];
}

- (void)showClipView:(NSString*)url{
	
	ClipController* tc = [self getViewCtr];
	
	ClipPlayController *clipCtr = [ClipPlayController new];
	
	clipCtr.clipURL = url;
	clipCtr.favorite = TRUE;
	clipCtr.showLike = FALSE;
	clipCtr.standalone = false;
	
	clipCtr.modalPresentationStyle = UIModalPresentationCurrentContext;
	clipCtr.delegate = tc;
	
	[tc presentViewController:clipCtr animated:YES completion:nil];
}

- (void)setCellData:(ArticleEntity*) entity isForHeight:(BOOL)isForHeight {
	
	self.webImageView.size = CGSizeMake(kScreenWidth, _cellHeight);
	
	_label.frame = _webImageView.frame;
	_errLabel.frame = _webImageView.frame;
	
	_shareBtn.bottom = _webImageView.bottom;
	_shareBtn.right = _webImageView.right;
	
	_albumBtn.bottom = _webImageView.bottom;
	_albumBtn.left = _webImageView.left;
	
	[self setCellProgressLayer];

	if(!isForHeight) [self setImageURL:[NSURL URLWithString:entity.url]];
}

- (void)setCellProgressLayer {
	_progressLayer.size = CGSizeMake(_webImageView.width, _cellHeight);
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:CGPointMake(0, _progressLayer.height / 2)];
	[path addLineToPoint:CGPointMake(_webImageView.width, _progressLayer.height / 2)];
	_progressLayer.path = path.CGPath;
	_progressLayer.lineWidth = _cellHeight;
}

- (void)setImageURL:(NSURL *)url {
	
	__weak typeof(self) _self = self;
	
	[CATransaction begin];
	[CATransaction setDisableActions: YES];
	self.progressLayer.hidden = YES;
	self.progressLayer.strokeEnd = 0;
	[CATransaction commit];
	
	_label.hidden = NO;
	_downLoaded = NO;
	_errLabel.hidden = YES;
	_heartButton.hidden = YES;
	_commentBtn.hidden = YES;
	_shareBtn.hidden = YES;
	_albumBtn.hidden = YES;
	_webImageView.autoPlayAnimatedImage = NO;
	[self setInitBorder];
	
	[_webImageView yy_setImageWithURL:url
						  placeholder:nil
							  options:YYWebImageOptionProgressiveBlur |YYWebImageOptionSetImageWithFadeAnimation | YYWebImageOptionShowNetworkActivity
							 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
								 if (expectedSize > 0 && receivedSize > 0) {
									 CGFloat progress = (CGFloat)receivedSize / expectedSize;
									 progress = progress < 0 ? 0 : progress > 1 ? 1 : progress;
									 if (_self.progressLayer.hidden) _self.progressLayer.hidden = NO;
									 _self.progressLayer.strokeEnd = progress;
								 }
							 }
							transform:nil
						   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
							   if (stage == YYWebImageStageFinished) {
								   _self.progressLayer.hidden = YES;
								   
								   if (!image) {
									   _self.errLabel.hidden = NO;
								   }else {
									   _self.downLoaded = YES;
									   _self.label.hidden = YES;
									   _self.heartButton.hidden = NO;
									   _self.commentBtn.hidden = NO;
									   _self.shareBtn.hidden = NO;
									   _self.albumBtn.hidden = NO;
									   
									   [_self unSetBorder];
									   [_self updateAutoplay];
									   [_self updateCommentQty];
									   [_self updateHeartButton:[url absoluteString]];
									   [_self updateAlbumButton:[url absoluteString]];
								   }
							   }
						   }
	 ];
}

- (ClipController *) getViewCtr {
	return self.delegate;
}

- (BOOL)isFullyVisible {
	ClipController* ctr = [self getViewCtr];	
	return [ctr needToPlay:self];
}

- (void)updateAutoplay {
	if ([self isFullyVisible]) {
		[self.webImageView startAnimating];
		[self setBorder];
	}
}

- (void)updateHeartButton:(NSString *)url {
	ClipController* ctr = [self getViewCtr];
	if([ctr isFavoriate:url]) {
		[self.heartButton selectWithNoAnim];
	}else {
		[self.heartButton deselectWithNoAnim];
	}
}

- (void)updateCommentQty {
	ClipController* ctr = [self getViewCtr];
	NSString *qty = [ctr getCommentQty:[self.webImageView.yy_imageURL absoluteString]];
	if(qty == nil) {
		return;
	}
	UIImage* commentsImage = [self createCommentIconWithCount: [qty intValue]];
	[_commentBtn setImage:commentsImage forState:UIControlStateNormal];
	[_commentBtn setImage:commentsImage forState:UIControlStateHighlighted];
}

- (void)displayComment {
	ClipController* ctr = [self getViewCtr];
	[ctr showComments:[self.webImageView.yy_imageURL absoluteString]];
}

- (void)shareClip {
	ClipController* ctr = [self getViewCtr];
	[ctr shareClip:self.webImageView.yy_imageURL];
}

- (void)collectClipToAlbum {
	ClipController* ctr = [self getViewCtr];
	[ctr formActionForCell:self withActionType:addToAlbum];
}

- (void)editClipInAlbum {
	ClipController* ctr = [self getViewCtr];
	[ctr formActionForCell:self withActionType:editClip];
}

- (void)setBorder {
	if(!_downLoaded) {
		return;
	}
	[_webImageView.layer setBorderColor: [[UIColor colorWithRed:255.0 / 255.0 green:64.0 / 255.0 blue:0.0 / 255.0 alpha:1.0] CGColor]];
	[_webImageView.layer setBorderWidth: 3.0];
	[_webImageView.layer setCornerRadius: 5.0];
}

- (void)setInitBorder {
	[_webImageView.layer setBorderColor: [[UIColor lightGrayColor] CGColor]];
	[_webImageView.layer setBorderWidth: 2.0];
	[_webImageView.layer setCornerRadius: 0.0];
}

- (void)unSetBorder {
	if(!_downLoaded) {
		return;
	}
	[_webImageView.layer setBorderColor: [[UIColor clearColor] CGColor]];
	[_webImageView.layer setBorderWidth: 0.0];
	[_webImageView.layer setCornerRadius: 0.0];
}

- (void)updateAlbumButton:(NSString *)url {
	ClipController* ctr = [self getViewCtr];
	if([ctr isCollected:url]) {
		[self.albumBtn selectWithNoAnim];
	}else{
		[self.albumBtn deselectWithNoAnim];
	}
}

- (void)selectAlbumButton {
	[self.albumBtn select];
}

- (void)sayHelloToFromCell {
	ClipController* ctr = [self getViewCtr];
	[ctr helloFromCell:self];
}

- (UIImage *)createCommentIconWithCount:(NSInteger)count {
	
	CGSize iconSize = CGSizeMake(25, 27);
	
	UIGraphicsBeginImageContextWithOptions(iconSize, NO, 0.0);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
	
	CGRect bubbleRect = CGRectMake(1, 1+iconSize.height*0.05, iconSize.width-2, (iconSize.height*0.69)-2);
	
	CGFloat minx = CGRectGetMinX(bubbleRect), midx = CGRectGetMidX(bubbleRect), maxx = CGRectGetMaxX(bubbleRect);
	CGFloat miny = CGRectGetMinY(bubbleRect), midy = CGRectGetMidY(bubbleRect), maxy = CGRectGetMaxY(bubbleRect);
	
	CGFloat radius = 3.0;
	// Start at 1
	CGContextMoveToPoint(context, minx, midy);
	// Add an arc through 2 to 3
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	// Add an arc through 4 to 5
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	
	// Add an arc through 6 to 7
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	
	CGContextAddLineToPoint(context, midx, maxy);
	CGContextAddLineToPoint(context, midx-5, maxy+5);
	CGContextAddLineToPoint(context, midx-5, maxy);
	
	// Add an arc through 8 to 9
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	// Close the path
	CGContextClosePath(context);
	
	// Fill & stroke the path
	CGRect countLabelRect = CGRectOffset(bubbleRect, 0, -1);
	UILabel *countLabel = [[UILabel alloc] initWithFrame:countLabelRect];
	NSString *fontName = @"HelveticaNeue-Bold";
	[countLabel setFont:[UIFont fontWithName:fontName size:12]];
	NSString *labelString;
	
	if(count == -1){
		labelString = @"";
	} else if (count > 99) {
		labelString = @"99+";
	} else {
		labelString = [NSString stringWithFormat:@"%li", (long)count];
	}
	
	[countLabel setText:labelString];
	[countLabel setTextAlignment:NSTextAlignmentCenter];
	if(true){
		CGContextFillPath(context);
		CGContextSaveGState(context);
		CGContextSetBlendMode(context, kCGBlendModeSourceOut);
		[countLabel drawTextInRect:countLabelRect];
		CGContextRestoreGState(context);
	} else {
		CGContextStrokePath(context);
		[countLabel drawTextInRect:countLabelRect];
	}
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

@end
