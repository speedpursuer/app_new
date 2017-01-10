//
//  Favorite.h
//  Cliplay
//
//  Created by 邢磊 on 2016/12/1.
//
//

#import "CBLBaseModelConflict.h"

@interface Favorite : CBLBaseModelConflict
@property NSArray *clips;
+ (Favorite*) getFavoriteInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid;
- (BOOL)isFavoriate:(NSString *)url;
- (void)setFavoriate:(NSString *)url;
- (void)unsetFavoriate:(NSString *)url;
@end
