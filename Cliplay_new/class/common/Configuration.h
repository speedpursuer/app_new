//
//  Configuration.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/20.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CliplayBaseSettings.h"

#define ratio16_9   (float)9/16
#define ratio4_3    (float)3/4
#define ratio16_10  (float)10/16

@interface Configuration : CliplayBaseSettings
@property NSNumber *displayRatio;
@property NSNumber *cacheLimit;
@end
