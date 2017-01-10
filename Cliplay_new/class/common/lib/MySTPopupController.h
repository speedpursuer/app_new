//
//  MySTPopupController.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/26.
//
//

#import <STPopup/STPopup.h>

@protocol AddAlbumDelegate <NSObject>
- (void)addToNewAlbum;
- (void)addExistingAlbum:(NSString *)albumID;
@end

@interface MySTPopupController : STPopupController
@property (nonatomic, weak) id<AddAlbumDelegate> delegate;
- (void)addToNewAlbum;
- (void)addExistingAlbum:(NSString *)albumID;
@end

