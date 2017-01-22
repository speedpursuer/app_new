//
//  PostTableViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/13.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "PostTableViewController.h"
#import "NewsTableViewCell.h"
#import "NoContent.h"

@interface PostTableViewController ()
@property NSArray *news;
@end

@implementation PostTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadPosts];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)segmentTitle {
	return NSLocalizedString(@"Album", @"Player tab");
}

-(void)loadPosts {
	_news = [[CBLService sharedManager] newsForPlayer:_player];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (_news.count > 0) {
		return 1;
	} else {
		NoContent *view = [[[NSBundle mainBundle] loadNibNamed:@"NoContent" owner:nil options:nil] lastObject];
		view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
		view.message.text = NSLocalizedString(@"No Content", @"for tableView");
		view.toBottom.constant = (self.view.bounds.size.height - 244)/2;
		self.tableView.backgroundView = view;
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		return 0;		
		
//		UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
//		messageLabel.text = @"无内容显示";
//		messageLabel.textColor = [UIColor lightGrayColor];
//		messageLabel.numberOfLines = 0;
//		messageLabel.textAlignment = NSTextAlignmentCenter;
//		messageLabel.font = [UIFont systemFontOfSize:20];
//		[messageLabel sizeToFit];
//		self.tableView.backgroundView = messageLabel;
//		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//		return 0;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _news.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"news" forIndexPath:indexPath];
    
	News *news = _news[indexPath.row];
	[cell setCellData:news.thumb name:news.name desc:news.desc];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	News *news = _news[indexPath.row];
	ClipController *vc = [ClipController new];
	vc.header = news.name;
	vc.summary = news.summary;
	vc.content = news;
	vc.postID = news.docID;
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
