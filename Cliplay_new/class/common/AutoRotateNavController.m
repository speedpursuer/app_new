//
//  AutoRotateNavController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/18.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "AutoRotateNavController.h"
#import "ClipPlayController.h"
#import "SlowPlayViewController.h"

@interface AutoRotateNavController ()

@end

@implementation AutoRotateNavController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
	if([self isInSlowPlayMode]){
		return YES;
	}else {
		return NO;
	}
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if([self isInSlowPlayMode]){
		return UIInterfaceOrientationMaskPortrait |UIInterfaceOrientationMaskLandscape;
	}else {
		return UIInterfaceOrientationMaskPortrait;
	}
}

- (BOOL)isInSlowPlayMode {
	return [self.visibleViewController isKindOfClass:[SlowPlayViewController class]];
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
