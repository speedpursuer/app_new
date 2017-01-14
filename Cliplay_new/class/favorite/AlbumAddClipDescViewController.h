//
//  AlbumAddClipDescViewController.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/26.
//
//

#import <UIKit/UIKit.h>
#import "DEComposeTextView.h"
#import "ClipController.h"

@interface AlbumAddClipDescViewController : UIViewController
@property (weak, nonatomic) IBOutlet DEComposeTextView *desc;
@property NSString *currDesc;
@property NSString *url;
@property BOOL shouldSave;
@property (weak) ClipController *delegate;
@end
