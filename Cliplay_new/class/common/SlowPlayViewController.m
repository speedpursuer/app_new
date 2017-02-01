//
//  SlowPlayViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/23.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "SlowPlayViewController.h"
#import "YYImageExampleHelper.h"
#import <FontAwesomeKit/FAKIonIcons.h>

@interface SlowPlayViewController ()
@property (weak, nonatomic) IBOutlet UIButton *close;

@end

@implementation SlowPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupView];
    // Do any additional setup after loading the view from its nib.
}

- (void)setupView {
	self.view.backgroundColor = [UIColor blackColor];
	[self setupButtons];
	[self setupImageView];
}

- (void)setupImageView {
	_imageView.backgroundColor = [UIColor blackColor];
	_imageView.contentMode = UIViewContentModeScaleAspectFit;
	[YYImageExampleHelper addTapControlToAnimatedImageView:_imageView];
	_imageView.yy_imageURL = [NSURL URLWithString:_url];
}

- (void)setupButtons {
	CGSize size = CGSizeMake(40, 40);
	FAKIonIcons *icon1 = [FAKIonIcons iosCloseEmptyIconWithSize:70];
	[_close setTintColor:[UIColor whiteColor]];
	[_close setImage:[icon1 imageWithSize:size] forState:UIControlStateNormal];
	[_close setImage:[icon1 imageWithSize:size] forState:UIControlStateHighlighted];
}

- (IBAction)exitSlowPlay:(id)sender{
	[self prepareToExit];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareToExit {
	[_imageView yy_cancelCurrentImageRequest];
	[[UIDevice currentDevice] setValue:
	 [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
								forKey:@"orientation"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL)isInLandscapeMode {
	return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
