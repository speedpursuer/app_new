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
#import "PushService.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ClipPlayController()
@property (nonatomic, strong) FRDLivelyButton *closeButton;
@property (nonatomic, assign) CGSize imageSize;
@end
@implementation ClipPlayController {
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setupImage];
	[self setupButtons];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if(_imageView && !_imageView.isAnimating) {
		[_imageView startAnimating];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[_imageView stopAnimating];
}

- (void)setupImage {
	self.view.backgroundColor = [UIColor blackColor];
	[self loadImage: self.clipURL];
}

- (void)loadImage: (NSString *)url {
	
	_imageView = [YYAnimatedImageView new];
	
	_imageView.clipsToBounds = YES;
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	_imageView.backgroundColor = [UIColor blackColor];
	
	__weak typeof(self) _self = self;
	
	[_imageView yy_setImageWithURL:[NSURL URLWithString:url]
					  placeholder:nil
						  options:YYWebImageOptionProgressiveBlur | YYWebImageOptionSetImageWithFadeAnimation | YYWebImageOptionShowNetworkActivity
						 progress:nil
						transform:nil
	 					   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error){
						   
						   if (stage == YYWebImageStageFinished) {
							   if(!error) {
								   _self.imageSize = image.size;
								   [_self setImageViewSize];
							   }
						   }
					   }
	 ];
	
	[self.view addSubview:_imageView];
	[YYImageExampleHelper addTapControlToAnimatedImageView:_imageView];
}

- (void) setImageViewSize {
	
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

- (void) setupButtons {
	
	_closeButton = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(6,[UIApplication sharedApplication].statusBarFrame.size.height+6,36,28)];
	[_closeButton setStyle:kFRDLivelyButtonStyleClose animated:NO];
	[_closeButton addTarget:self action:@selector(exitSlowPlay) forControlEvents:UIControlEventTouchUpInside];
	[_closeButton setOptions:@{
							   kFRDLivelyButtonLineWidth: @(2.0f),
							   kFRDLivelyButtonHighlightedColor: [UIColor colorWithRed:230.0 / 255.0 green:230.0 / 255.0 blue:230.0 / 255.0 alpha:1.0],
							   kFRDLivelyButtonColor: [UIColor whiteColor]
							   }];
	
	[self.view addSubview:_closeButton];
}

- (void)exitSlowPlay{
	PushService *service = [PushService new];
	[service fetchData];
	return;

	[self prepareToExit];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareToExit {
	[_imageView yy_cancelCurrentImageRequest];
	[[UIDevice currentDevice] setValue:
	 [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
								forKey:@"orientation"];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	[self resetUIPosition];
	
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait) {
		[self setPortaitMode];
	} else {
		[self setLandscapeMode];
	}
}

- (void)setPortaitMode {
	_isInLandscapeMode = NO;
	[self showBar];
}

- (void)setLandscapeMode {
	_isInLandscapeMode = YES;
	[self hideBar];
}

- (void)resetUIPosition {
	
	[self setImageViewSize];
	
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
	
	CGRect f3 = CGRectMake(6, statusBarHeight + 6,36,28);
	_closeButton.frame = f3;
}

-(void)changeOrientation {
	[[UIDevice currentDevice] setValue:
	 [NSNumber numberWithInteger: UIDeviceOrientationLandscapeRight]
								forKey:@"orientation"];
}

- (void)showBar {
	[[[self navigationController] navigationBar] setHidden:NO];
	[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}

- (void)hideBar {
	[[[self navigationController] navigationBar] setHidden:YES];
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
