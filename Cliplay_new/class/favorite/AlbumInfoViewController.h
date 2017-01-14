//
//  AlbumInfoViewController.h
//  Cliplay
//
//  Created by 邢磊 on 2016/12/28.
//
//

#import <UIKit/UIKit.h>
#import "ClipController.h"

@interface AlbumInfoViewController : UITableViewController <UITextFieldDelegate>
@property NSString *name;
@property NSString *desc;
@property BOOL shouldSave;
@property (weak) ClipController *delegate;
@end
