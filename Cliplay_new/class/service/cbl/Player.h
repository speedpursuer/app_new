//
//  Players.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/10.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CBLBaseModel.h"

@interface Player : CBLBaseModel
@property NSString *name;
@property NSString *name_en;
@property NSString *avatar;
@property NSInteger sectionNumber;
@property NSString *player_image;
@property NSArray *news;
@property NSString *lastName;
@end
