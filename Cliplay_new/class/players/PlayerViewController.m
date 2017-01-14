//
//  CustomHeaderViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/12.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "PlayerViewController.h"
#import "MovesTableViewController.h"
#import "PostTableViewController.h"
#import "UIImage+ImageEffects.h"
#import "CacheManager.h"
#import "PlayerBanner.h"

#define ksegmentTopInset @"segmentTopInset"

@interface PlayerViewController ()
@property (nonatomic, strong) UIImage *defaultImage;
@property (nonatomic, strong) UIImage *blurImage;
@property (nonatomic, strong) PlayerBanner *header;
@end

@implementation PlayerViewController

- (instancetype)initWithPlayer:(Player *)player {
	
	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"players" bundle:nil];
	
	MovesTableViewController *moveVC = [sb instantiateViewControllerWithIdentifier:@"moves"];
	moveVC.player = player;
	
	PostTableViewController *postVC = [sb instantiateViewControllerWithIdentifier:@"posts"];
	postVC.player = player;
		
	self = [super initWithControllers:moveVC, postVC, nil];
	if (self) {
		self.segmentMiniTopInset = 64;
		self.headerHeight = 200;
//		self.freezenHeaderWhenReachMaxHeaderHeight = YES;
		self.player = player;
	}
	
	return self;
}

-(UIView<ARSegmentPageControllerHeaderProtocol> *)customHeaderView
{
	if (_header == nil) {
		_header = [[[NSBundle mainBundle] loadNibNamed:@"PlayerBanner" owner:nil options:nil] lastObject];
		_header.backgroundColor = [UIColor redColor];
	}
	return _header;
}

-(BOOL)hidesBottomBarWhenPushed {
	return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self configture];
	[self setupNavBarStyle];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configture {
	[self configPlayerImage];
	[self addObserver:self forKeyPath:ksegmentTopInset options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)configPlayerImage {
	
	[self.header setName:_player.name];
	
	UIImage *blank = [UIImage imageNamed:@"blank.jpg"];
	self.defaultImage = blank;
	self.blurImage = [blank applyDarkEffect];
	
	UIImageView *imageView = [self.headerView backgroundImageView];
	
	__weak typeof(self) _self = self;
	[imageView requestSImageWithURL:_player.player_image
					withPlaceholder:blank
						 completion:^(UIImage * image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
							 if (stage == YYWebImageStageFinished) {
								 if (image) {
									 _self.defaultImage = image;
									 _self.blurImage = [image applyDarkEffect];
								 }
							 }
						 }
	];
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:ksegmentTopInset];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	if([keyPath isEqualToString:ksegmentTopInset]) {
		CGFloat topInset = [change[NSKeyValueChangeNewKey] floatValue];
		[self updateImageAndTitle:topInset];
		[self updatePlayerName:topInset];
	}
}

-(void)updateImageAndTitle:(CGFloat)topInset{
	UIImageView *imageView = [self.headerView backgroundImageView];
	if (topInset <= self.segmentMiniTopInset) {
		self.title = self.player.name;
		imageView.image = self.blurImage;
	}else{
		self.title = nil;
		imageView.image = self.defaultImage;
	}
}

-(void)updatePlayerName:(CGFloat)topInset{
	if (topInset < self.headerHeight) {
		[self.header setName:@""];
	}else{
		[self.header setName:_player.name];
	}
}

- (void)setupNavBarStyle {
	[self.navigationController.navigationBar setBackgroundImage:[self createImageWithColor:[UIColor clearColor]] forBarMetrics:UIBarMetricsDefault];
	[self.navigationController.navigationBar setShadowImage:[self createImageWithColor:[UIColor clearColor]]];
}

-(UIImage *)createImageWithColor: (UIColor *) color
{
	CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return theImage;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


//- (void)configNavbar1 {
//	NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
//											   [UIColor whiteColor],NSForegroundColorAttributeName,
//											   [UIFont systemFontOfSize:18],
//											   NSFontAttributeName, nil];
//	
//	[self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
//	
//	[self.navigationController.navigationBar setBackgroundImage:[self createImageWithColor:[UIColor clearColor]] forBarMetrics:UIBarMetricsDefault];
//	
//	[self.navigationController.navigationBar setShadowImage:[self createImageWithColor:[UIColor clearColor]]];
//	[self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
//	[self.navigationController.navigationBar setTranslucent:NO];
//	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
//}
//
//- (void)revertNavbar1 {
//	NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
//											   [UIColor blackColor],NSForegroundColorAttributeName,
//											   [UIFont systemFontOfSize:18],
//											   NSFontAttributeName, nil];
//	
//	[self.navigationController.navigationBar setTitleTextAttributes:navbarTitleTextAttributes];
//	
//	self.navigationController.navigationBar.barTintColor = [UIColor redColor];
//	
//	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//	
//	[self.navigationController.navigationBar setShadowImage:nil];
//	
//	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
//	[self.navigationController.navigationBar setTranslucent:NO];
//	[self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
//	
//	[self.navigationController.navigationBar setBarTintColor:nil];
//}

//- (void)revertNavbar {
//	[self.navigationController.navigationBar setBackgroundImage:[self createImageWithColor:CLIPLAY_COLOR] forBarMetrics:UIBarMetricsDefault];
//	[self.navigationController.navigationBar setShadowImage:[self createImageWithColor:CLIPLAY_COLOR]];
//	[self.navigationController.navigationBar setBarTintColor:CLIPLAY_COLOR];
//	
//	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//	[self.navigationController.navigationBar setShadowImage:nil];
//	[self.navigationController.navigationBar setBarTintColor:CLIPLAY_COLOR];
//}

@end
