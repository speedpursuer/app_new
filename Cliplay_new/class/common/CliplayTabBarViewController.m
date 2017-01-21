//
//  CliplayTabBarViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CliplayTabBarViewController.h"
#import <FontAwesomeKit/FAKIonIcons.h>
#import "ClipPlayController.h"
#import "AppDelegate.h"

@interface CliplayTabBarViewController ()

@end

@implementation CliplayTabBarViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	[self configureCtrs];
	[self configureTabBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureTabBar {

	UITabBar *tabBar = self.tabBar;
	UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
	UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
	UITabBarItem *tabBarItem3 = [tabBar.items objectAtIndex:2];
	
	tabBarItem1.title = @"最新内容";
	tabBarItem2.title = @"球星动作";
	tabBarItem3.title = @"我的球路";
	
	CGSize size = CGSizeMake(30, 30);
	
	FAKIonIcons *icon1 = [FAKIonIcons iosPaperOutlineIconWithSize:30];
	[tabBarItem1 setImage:[icon1 imageWithSize:size]];
	FAKIonIcons *iconSelected1 = [FAKIonIcons iosPaperIconWithSize:30];
	[tabBarItem1 setSelectedImage:[iconSelected1 imageWithSize:size]];
	
	FAKIonIcons *icon2 = [FAKIonIcons iosStarOutlineIconWithSize:30];
	[tabBarItem2 setImage:[icon2 imageWithSize:size]];
	FAKIonIcons *iconSelected2 = [FAKIonIcons iosStarIconWithSize:30];
	[tabBarItem2 setSelectedImage:[iconSelected2 imageWithSize:size]];
	
	FAKIonIcons *icon3 = [FAKIonIcons iosBasketballOutlineIconWithSize:30];
	[tabBarItem3 setImage:[icon3 imageWithSize:size]];
	FAKIonIcons *iconSelected3 = [FAKIonIcons iosBasketballIconWithSize:30];
	[tabBarItem3 setSelectedImage:[iconSelected3 imageWithSize:size]];
	
	[[UITabBar appearance] setTintColor:CLIPLAY_COLOR];
}

- (void)configureCtrs {
	NSArray *ctrNames = @[@"news", @"players", @"favorite"];
	NSArray *ctrs = [self.viewControllers copy];
	[ctrNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *name = (NSString *)obj;
		UIStoryboard *sb = [UIStoryboard storyboardWithName:name bundle:nil];
		UIViewController *vc = [sb instantiateViewControllerWithIdentifier:name];
		[(UINavigationController *)ctrs[idx] pushViewController:vc animated:NO];
	}];
}

- (BOOL)shouldAutorotate {
	return [self.selectedViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return [self.selectedViewController supportedInterfaceOrientations];
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
