//
//  ClipPlayController.m
//  Cliplay
//
//  Created by 邢磊 on 16/1/14.
//
//

#import "ClipPlayController.h"
#import "CacheManager.h"
#import "UIView+YYAdd.h"
#import "YYImageExampleHelper.h"
#import <sys/sysctl.h>
#import "MBCircularProgressBarView.h"
#import "FRDLivelyButton.h"
#import "DOFavoriteButton.h"
#import "UIGestureRecognizer+YYAdd.h"
//#import "PushService.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ClipPlayController()
@property (nonatomic, strong) MBCircularProgressBarView *progressBar;
@property (nonatomic, strong) DOFavoriteButton *heartButton;
@property (nonatomic, strong) FRDLivelyButton *closeButton;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) CGSize imageSize;
//@property BOOL dismissed;

@end
@implementation ClipPlayController {
	BOOL download;
	BOOL iniFavorite;
	BOOL hideBar;
}

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	[self loadImage: self.clipURL];
	
	[self initButtons];
	
	hideBar = FALSE;
}

//- (void)viewDidDisappear:(BOOL)animated {
//	[super viewDidDisappear:animated];
//	_dismissed = YES;
//	[UIViewController attemptRotationToDeviceOrientation];
//}

//- (void)viewWillDisappear:(BOOL)animated {
//	[super viewWillDisappear:animated];
//	_dismissed = YES;
//	[UIViewController attemptRotationToDeviceOrientation];
//}


- (void)loadImage: (NSString *)url {
	
	_imageView = [YYAnimatedImageView new];
	
	_loaded = false;
	download = false;
	
	//	imageView.height = self.view.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
	
	//imageView.size = self.view.size;
	_imageView.clipsToBounds = YES;
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	_imageView.backgroundColor = [UIColor blackColor];
	
	//	_progressBar = [[MBCircularProgressBarView alloc] initWithFrame:CGRectMake((imageView.width-100)/2, (imageView.height-100)/2, 100, 100)];
	
	_progressBar = [[MBCircularProgressBarView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-100)/2, (self.view.bounds.size.height-100)/2, 100, 100)];
	
	
	_progressBar.backgroundColor = [UIColor clearColor];
	_progressBar.hidden = YES;
	
	__weak typeof(self) _self = self;
	
	[NSTimer scheduledTimerWithTimeInterval:0.3
									 target:self
								   selector:@selector(showProgress)
								   userInfo:nil
									repeats:NO];
	
	[_imageView yy_setImageWithURL:[NSURL URLWithString:url]
					  placeholder:nil
						  options:YYWebImageOptionProgressiveBlur | YYWebImageOptionSetImageWithFadeAnimation | YYWebImageOptionShowNetworkActivity
						 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
							 _progressBar.hidden = NO;
							 if (expectedSize > 0 && receivedSize > 0) {
								 CGFloat progress = (CGFloat)receivedSize / expectedSize;
								 progress = progress < 0 ? 0 : progress > 1 ? 1 : progress;
								 if (_self.progressBar.hidden && progress != 1) _self.progressBar.hidden = NO;
								 [_self.progressBar setValue: progress * 100 animateWithDuration:1];
							 }
						 }
						transform:nil
	 					   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error){
						   
						   if (stage == YYWebImageStageFinished) {
							   if(!error) {
								   [_self.progressBar setValue: 100 animateWithDuration:1];
								   _self.progressBar.hidden = YES;
								   _self.imageSize = image.size;
								   _self.loaded = true;
								   [_self setImageViewSize];
							   }else {
								   [_self.progressBar setValue: 0 animateWithDuration:1];
								   NSString *title, *message;
								   if(error.code == -1009){
									   title = @"无法下载";
									   message = @"请确认互联网连接。";
								   }else{
									   title = @"下载出现异常";
									   message = @"非常抱歉，请稍候再尝试。";
								   }
								   
								   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
																				   message:message
																				  delegate:nil
																		 cancelButtonTitle:@"好"
																		 otherButtonTitles:nil];
								   [alert show];
							   }
						   }
					   }
	 ];
	
	[self.view addSubview:_imageView];
	[self.view addSubview:_progressBar];
	
	[YYImageExampleHelper addTapControlToAnimatedImageView:_imageView];
//	[YYImageExampleHelper addPanControlToAnimatedImageView:_imageView];
}

- (void)addTapControlToAnimatedImageView:(YYAnimatedImageView *)view {
	if (!view) return;
	view.userInteractionEnabled = YES;
	__weak typeof(self) _self = self;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
		[_self exitSlowPlay];
	}];
	
	tap.numberOfTapsRequired = 2;
	
	[view addGestureRecognizer:tap];
}

- (void) setImageViewSize {
	
	if(!_loaded) return;
	
	CGFloat imageWidthToHeight = _imageSize.width / _imageSize.height;
	CGFloat viewWidthToHeight = self.view.bounds.size.width / self.view.bounds.size.height;
	
	if(viewWidthToHeight > imageWidthToHeight) {
		CGFloat imageViewWidth = self.view.bounds.size.height * imageWidthToHeight;
		CGFloat left = (self.view.bounds.size.width - imageViewWidth) / 2;
		CGRect frame = CGRectMake(left, 0.0f, imageViewWidth, self.view.bounds.size.height);
		_imageView.frame = frame;
		
	}else {
		
		if(self.interfaceOrientation == UIInterfaceOrientationPortrait) {
			CGRect frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height);
			_imageView.frame = frame;
		}else {
			CGFloat imageViewHeight = self.view.bounds.size.width / imageWidthToHeight;
			CGFloat top = (self.view.bounds.size.height - imageViewHeight) / 2;
			CGRect frame = CGRectMake(0.0f, top, self.view.bounds.size.width, imageViewHeight);
			_imageView.frame = frame;
		}
	}
}

- (void) initButtons {
	
	iniFavorite = self.favorite;
	
	_closeButton = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(6,[UIApplication sharedApplication].statusBarFrame.size.height+6,36,28)];
	[_closeButton setStyle:kFRDLivelyButtonStyleClose animated:NO];
	[_closeButton addTarget:self action:@selector(exitSlowPlay) forControlEvents:UIControlEventTouchUpInside];
	[_closeButton setOptions:@{
							   kFRDLivelyButtonLineWidth: @(2.0f),
							   kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:230.0 / 255.0 green:230.0 / 255.0 blue:230.0 / 255.0 alpha:1.0],
							   kFRDLivelyButtonColor: [UIColor whiteColor]
							   }];
	
	[self.view addSubview:_closeButton];
	
	if (self.showLike) {
		
		_heartButton = [[DOFavoriteButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44,[UIApplication sharedApplication].statusBarFrame.size.height, 44, 44) image:[UIImage imageNamed:@"heart"] selected: false];
		
		_heartButton.imageColorOn = CLIPLAY_COLOR;
		_heartButton.circleColor = CLIPLAY_COLOR;
		_heartButton.lineColor = [UIColor colorWithRed:245.0 / 255.0 green:54.0 / 255.0 blue:0.0 / 255.0 alpha:1.0];
		
		[_heartButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
		
		if(self.favorite) [_heartButton select];
		[self.view addSubview:_heartButton];
	}
}

- (void)tappedButton:(DOFavoriteButton *)sender {
	self.favorite = !sender.selected;
	if (sender.selected) {
		[sender deselect];
	} else {
		[sender select];
	}
}

- (void)exitSlowPlay{
	
//	PushService *service = [PushService new];
//	[service fetchData];
//	return;
	
	[self prepareToExit];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareToExit {
	[_imageView yy_cancelCurrentImageRequest];
	[[UIDevice currentDevice] setValue:
	 [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
								forKey:@"orientation"];
}

- (void)showProgress{
	if (!_loaded) {
		_progressBar.hidden = NO;
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	[self resetUIPosition];
	
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait) {
		//[self showButton];
		[self setPortaitMode];
	} else {
		//[self hideButton];
		[self setLandscapeMode];
	}
}

- (void)showButton {
	_heartButton.hidden = FALSE;
	_closeButton.hidden = FALSE;
}

- (void)hideButton {
	_heartButton.hidden = TRUE;
	_closeButton.hidden = TRUE;
}

- (void)setPortaitMode {
	_isInLandscapeMode = NO;
	_heartButton.imageColorOff = [UIColor colorWithRed:136.0 / 255.0 green:153.0 / 255.0 blue:166.0 / 255.0 alpha:1.0];
	[_progressBar setEmptyLineColor:[UIColor lightGrayColor]];
	[_progressBar setFontColor:[UIColor darkGrayColor]];
	
//	[_closeButton setOptions:@{
//							   kFRDLivelyButtonLineWidth: @(2.0f),
//							   kFRDLivelyButtonHighlightedColor: [UIColor lightGrayColor],
//							   kFRDLivelyButtonColor: [UIColor colorWithRed:68.0 / 255.0 green:68.0 / 255.0 blue:68.0 / 255.0 alpha:1.0]
//							   }];
//	self.view.backgroundColor = [UIColor blackColor];
	[self showBar];
}

- (void)setLandscapeMode {
	_isInLandscapeMode = YES;
	_heartButton.imageColorOff = [UIColor whiteColor];
	[_progressBar setEmptyLineColor:[UIColor whiteColor]];
	[_progressBar setFontColor:[UIColor whiteColor]];
//	[_closeButton setOptions:@{
//							   kFRDLivelyButtonLineWidth: @(2.0f),
//							   kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:230.0 / 255.0 green:230.0 / 255.0 blue:230.0 / 255.0 alpha:1.0],
//							   kFRDLivelyButtonColor: [UIColor whiteColor]
//							   }];
//	self.view.backgroundColor = [UIColor blackColor];
	[self hideBar];
}

- (void)resetUIPosition {
	
	[self setImageViewSize];
	//imageView.size = self.view.bounds.size;
	
	CGRect f1 = CGRectMake((self.view.bounds.size.width-100)/2, (self.view.bounds.size.height-100)/2, 100, 100);
	_progressBar.frame = f1;
	
	CGFloat statusBarHeight;
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
		statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
	}else{
		if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
			statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
		}else{
			statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
		}
	}
	
	CGRect f2 = CGRectMake(self.view.bounds.size.width - 44, statusBarHeight, 44, 44);
	_heartButton.frame = f2;
	
	CGRect f3 = CGRectMake(6, statusBarHeight + 6,36,28);
	_closeButton.frame = f3;
	
	[_progressBar setValue: _progressBar.value animateWithDuration:1];
}

-(void)changeOrientation {
	[[UIDevice currentDevice] setValue:
	 [NSNumber numberWithInteger: UIDeviceOrientationLandscapeRight]
								forKey:@"orientation"];
}

- (void)showBar {
	[[[self navigationController] navigationBar] setHidden:NO];
	hideBar = false;
	[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

- (void)hideBar {
	[[[self navigationController] navigationBar] setHidden:YES];
	hideBar = true;
	[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

#pragma mark - Status bar

-(UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

//- (BOOL)prefersStatusBarHidden {
//	return YES;
//}

@end
