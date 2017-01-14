//
//  NewsTableViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "NewsTableViewController.h"
#import "CBLService.h"
#import "News.h"
#import "ArticleEntity.h"
#import "NewsTableViewCell.h"
#import "ClipController.h"
#import "CBLService.h"
//#import <BOZPongRefreshControl/BOZPongRefreshControl.h>


@interface NewsTableViewController ()
@property NSArray *newsList;
@end

@implementation NewsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupRefresher];
	[self setupTitle];
	[self allNews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Init data

- (void)setupRefresher {
	[self.refreshControl addTarget:self action:@selector(syncStart) forControlEvents:UIControlEventValueChanged];
}

- (void)syncStart {
	[[CBLService sharedManager] syncStartWithDelegate:self];
}

- (void)syncEnd {
	[self.refreshControl endRefreshing];
}

- (void)allNews {
	CBLService *service = [CBLService sharedManager];
	_newsList = service.news;
}

- (void)setupTitle {
	self.title = @"最新信息";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _newsList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"news" forIndexPath:indexPath];
	News *news = _newsList[indexPath.row];
	[cell setCellData:news.thumb name:news.name desc:news.desc];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	ClipController *vc = [ClipController new];
	News *news = _newsList[indexPath.row];
	vc.header = news.name;
	vc.summary = news.summary;
	vc.post = news;
	[self.navigationController pushViewController:vc animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
