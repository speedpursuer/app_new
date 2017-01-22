//
//  CacheSettingViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/17.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CacheSettingViewController.h"
#import "CacheManager.h"
#import "AppSettings+Cliplay.h"

@interface CacheSettingViewController ()
@property (weak) CacheManager *manager;
@property UILabel *limitLabel;
@property int savedLimit;
@end

@implementation CacheSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setup];
    // Do any additional setup after loading the view.
}

- (void)setup {
	_manager = [CacheManager sharedManager];
	_cacheLimit.minimumValue = 200;
	_cacheLimit.maximumValue = 5000;
	_savedLimit = [_manager getCacheLimit];
	_cacheLimit.value = _savedLimit;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
	
	if (section == 0) {
		_limitLabel = header.textLabel;
		[self setLimitLableText:_savedLimit];
		
	}else{
		header.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Current total cache: %ldMB", @"Cache setup"), [_manager totalCached]];
	}
	header.textLabel.font = [UIFont boldSystemFontOfSize:16];
	header.textLabel.numberOfLines = 1;
}

- (IBAction)limitChanged:(UISlider *)slider {
	int intValue = ((int)((slider.value + 50) / 100) * 100);
	[slider setValue:intValue animated:YES];
	[self setLimitLableText:intValue];
}

- (void)setLimitLableText:(int)rawNumber {
	NSString *goodLookingValue;
	
	if(rawNumber < 1000) {
		goodLookingValue = [NSString stringWithFormat:@"%dMB", rawNumber];
	}else {
		goodLookingValue = [NSString stringWithFormat:@"%.1fG", (float)rawNumber/1000];;
	}
	_limitLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Auto cleanup to keep space below: %@", @"Cache setup"), goodLookingValue];
	
	[_limitLabel sizeToFit];
}

- (IBAction)goBack:(id)sender {
	if(sender == self.saveButton) {
		[_manager setCacheLimit:(int)_cacheLimit.value];
	}else if(sender == self.deleteButton) {
		[_manager deleteAllCache];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
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
