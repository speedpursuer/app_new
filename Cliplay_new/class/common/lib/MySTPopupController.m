//
//  MySTPopupController.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/26.
//
//

#import "MySTPopupController.h"

@implementation MySTPopupController
- (void)presentInViewController:(UIViewController *)viewController {
	[super presentInViewController:viewController];
	_delegate = (id<AddAlbumDelegate>)viewController;
}

- (void)addToNewAlbum{
	[_delegate addToNewAlbum];
}
- (void)addExistingAlbum:(NSString *)albumID{
	[_delegate addExistingAlbum:albumID];
}
@end
