//
//  BottomSheetTableViewController.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/25.
//
//

#import <UIKit/UIKit.h>
#import "MySTPopupController.h"
#import "Album.h"

@interface AlbumSelectBottomSheetViewController : UITableViewController
@property (nonatomic, strong) Album *selectedAlbum;
@end
