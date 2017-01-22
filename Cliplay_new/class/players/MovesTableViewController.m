//
//  MovesTableViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/11.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "MovesTableViewController.h"
#import "MovesTableViewCell.h"
#import <TLYShyNavBar/TLYShyNavBarManager.h>
#import "RoundUIImageView.h"
#import "NoContent.h"

@interface MovesTableViewController ()
@property NSArray *moves;
@end

@implementation MovesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadMoves];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)segmentTitle {
	return NSLocalizedString(@"Movement", @"Player tab");
}

-(void)loadMoves {
	_moves = [[CBLService sharedManager] movesForPlayer:_player];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (_moves.count > 0) {
		return 1;
	} else {
		NoContent *view = [[[NSBundle mainBundle] loadNibNamed:@"NoContent" owner:nil options:nil] lastObject];
		view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
		view.message.text = NSLocalizedString(@"No Content", @"for tableView");
		view.toBottom.constant = (self.view.bounds.size.height - 244)/2;
		self.tableView.backgroundView = view;
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		return 0;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _moves.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"moves" forIndexPath:indexPath];
	Move *move = _moves[indexPath.row];
	[cell setData:move.move_name desc:move.desc thumb:move.image];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	Move *move = _moves[indexPath.row];
	ClipController *vc = [ClipController new];
	Post *post = [[CBLService sharedManager] clipsForPlayer:_player withMove:move];
	vc.header = [NSString stringWithFormat:@"%@ - %@", _player.name, move.move_name];
	vc.content = post;
	vc.postID = post.docID;
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
