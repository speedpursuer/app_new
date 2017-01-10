//
//  BottomSheetTableViewController.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/25.
//
//

#import "AlbumSelectBottomSheetViewController.h"
#import "CBLService.h"
#import "AlbumListTableViewCell.h"
#import <FontAwesomeKit/FAKFontAwesome.h>

@interface AlbumSelectBottomSheetViewController ()
@property CBLService *service;
@property (nonatomic, strong) NSMutableArray *albums;
@property UIImage *addThumb;
@property UIImage *albumThumb;

@end

@implementation AlbumSelectBottomSheetViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		self.title = @"加入收藏夹";
		self.contentSizeInPopup = CGSizeMake(0, 250);
		self.landscapeContentSizeInPopup = CGSizeMake(0, 250);
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setup];
}

- (void)setup {
	_service = ((CBLService *)[CBLService sharedManager]);
	_albums = [NSMutableArray arrayWithArray:[_service getAllAlbums]];
	[self setupThumbs];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helper

- (void)setupThumbs {
	
	CGSize imageSize = CGSizeMake(40, 40);
	
	FAKFontAwesome *addIcon = [FAKFontAwesome plusIconWithSize:12];
	[addIcon addAttribute:NSForegroundColorAttributeName value:[UIColor redColor]];
	_addThumb = [addIcon imageWithSize:imageSize];
	
	FAKFontAwesome *albumIcon = [FAKFontAwesome folderOIconWithSize:35];
	[albumIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
	FAKFontAwesome *fileIcon = [FAKFontAwesome filmIconWithSize:12];
	[fileIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
	_albumThumb = [UIImage imageWithStackedIcons:@[albumIcon, fileIcon] imageSize:imageSize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_albums count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	AlbumListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"favorite"];
	
	if(indexPath.row == 0) {
		cell.title.text = @"新建收藏夹";
		[cell.thumb setImage:_addThumb];
		cell.badge.hidden = YES;
//		cell.detailTextLabel.text = @"";
	}else {
		Album *album = (self.albums)[indexPath.row - 1];
		cell.title.text = album.title;
		cell.badge.hidden = NO;
		cell.badge.text = [NSString stringWithFormat: @"%ld", album.clips.count];
		UIImage *thumb = [album getThumb];
		if(thumb == nil) {
			thumb =	_albumThumb;
		}
		[cell.thumb setImage:thumb];
//		cell.detailTextLabel.text = [@(album.clips.count) stringValue];
	}
	
	return cell;
	
//	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addCell"];
//	
//	if(indexPath.row == 0) {
//		cell.textLabel.text = @"+ 新建";
//		cell.detailTextLabel.text = @"";
//	}else {
//		Album *album = (self.albums)[indexPath.row - 1];
//		cell.textLabel.text = album.title;
//		cell.detailTextLabel.text = [@(album.clips.count) stringValue];
//	}
//	
//	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.popupController dismiss];
	if(indexPath.row == 0) {
		_selectedAlbum = nil;
	}else {
		_selectedAlbum = (self.albums)[indexPath.row - 1];
	}
	[self performSegueWithIdentifier:@"albumSelected" sender:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	NSLog(@"_selectedAlbumID = %@", _albumID);
}
 */
@end
