//
//  Client.h
//  Cliplay
//
//  Created by 邢磊 on 16/8/4.
//
//

#import "CliplayBaseSettings.h"

@interface User : CliplayBaseSettings
@property (nonatomic, copy) NSString *commentName;
@property (nonatomic, copy) NSString *commentAvatar;
@property (nonatomic, copy) NSString *commentAccountID;
@property (nonatomic, copy) NSString *shareAccountID;
@property (nonatomic, copy) NSString *shareWBAccessToken;
@property (nonatomic, copy) NSString *shareWBRefreshToken;
@end
