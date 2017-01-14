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
	
	tabBarItem1.title = @"最新信息";
	tabBarItem2.title = @"球星动作";
	tabBarItem3.title = @"我的收藏";
	
	CGSize size = CGSizeMake(30, 30);
	
	FAKIonIcons *basketball = [FAKIonIcons iosBasketballOutlineIconWithSize:30];
	[tabBarItem1 setImage:[basketball imageWithSize:size]];
	
	FAKIonIcons *players = [FAKIonIcons iosPeopleOutlineIconWithSize:30];
	[tabBarItem2 setImage:[players imageWithSize:size]];
	
	FAKIonIcons *favorite = [FAKIonIcons androidFavoriteOutlineIconWithSize:30];
	[tabBarItem3 setImage:[favorite imageWithSize:size]];
	
	[[UITabBar appearance] setTintColor:CLIPLAY_COLOR];
}

//- (void)configureNewsCtr {
//	NSArray *ctrs = [self.viewControllers copy];
//	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"news" bundle:nil];
//	UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"news"];
//	[(UINavigationController *)ctrs[0] pushViewController:vc animated:NO];
//}
//
//- (void)configurePlayersCtr {
//	NSArray *ctrs = [self.viewControllers copy];
//	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"players" bundle:nil];
//	UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"players"];
//	[(UINavigationController *)ctrs[1] pushViewController:vc animated:NO];
//}
//
//- (void)configureFavoriteCtr {
//	NSArray *ctrs = [self.viewControllers copy];
//	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"favorite" bundle:nil];
//	UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"favorite"];
//	[(UINavigationController *)ctrs[2] pushViewController:vc animated:NO];
//}

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

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if([[self topViewControllerWithRootViewController:self] isKindOfClass:[ClipPlayController class]]) {
		return UIInterfaceOrientationMaskAll;
	}else{
		return UIInterfaceOrientationMaskPortrait;
	}
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
	if ([rootViewController isKindOfClass:[UITabBarController class]]) {
		UITabBarController* tabBarController = (UITabBarController*)rootViewController;
		return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
	} else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController* navigationController = (UINavigationController*)rootViewController;
		return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
	} else if (rootViewController.presentedViewController) {
		UIViewController* presentedViewController = rootViewController.presentedViewController;
		return [self topViewControllerWithRootViewController:presentedViewController];
	} else {
		return rootViewController;
	}
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
