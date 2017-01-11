//
//  MovesTableViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/11.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "MovesTableViewController.h"
#import "MovesTableViewCell.h"

@interface MovesTableViewController ()
@property NSArray *moves;
@end

@implementation MovesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setupRefresher];
	[self loadMoves];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)hidesBottomBarWhenPushed {
	return YES;
}

- (void)setupRefresher {
	self.refreshControl = [[UIRefreshControl alloc] init];
	//	self.refreshControl.tintColor = [UIColor whiteColor];
	self.refreshControl.backgroundColor = [UIColor purpleColor];
	self.refreshControl.tintColor = [UIColor whiteColor];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:@"下拉刷新"];
	[self.refreshControl addTarget:self action:@selector(syncData) forControlEvents:UIControlEventValueChanged];
}

- (void)syncData {
	[self.refreshControl endRefreshing];
}

- (void)loadMoves {
	_moves = @[
				@{
					@"name": @"投篮",
					@"image": @"https://img.alicdn.com/imgextra/i4/18348931/TB2XfvfkpXXXXXkXXXXXXXXXXXX_!!18348931.png"
				},
				@{
					@"name": @"传球",
					@"image": @"https://img.alicdn.com/imgextra/i2/18348931/TB2z9iHkpXXXXcbXpXXXXXXXXXX_!!18348931.png"
				}
			 ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _moves.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"moves" forIndexPath:indexPath];
	
	NSDictionary *dict = _moves[indexPath.row];
	NSString *name = [dict valueForKey:@"name"];
	NSString *image = [dict valueForKey:@"image"];
	[cell setData:name thumb:image];
	
    return cell;
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
