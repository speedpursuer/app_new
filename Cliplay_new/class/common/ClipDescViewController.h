//
//  ClipDescViewController.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/21.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AutoRotateNavController.h"

typedef NS_ENUM(NSInteger, ClipDescActionType) {
	sendClip,
	addDesc,
	editDesc,
};

@protocol ClipDescDelegate <NSObject>
@optional
-(void)saveDesc:(NSString *)desc;
-(void)sendClip:(NSString *)url desc:(NSString *)desc;
@end

@interface ClipDescViewController : UIViewController
@property NSString *desc;
@property NSString *url;
@property NSString *descPlaceholder;
@property ClipDescActionType actionType;
@property (weak) id<ClipDescDelegate> delegate;

@end
