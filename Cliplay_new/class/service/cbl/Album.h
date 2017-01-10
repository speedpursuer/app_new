//
//  Album.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/3.
//
//

#import <Foundation/Foundation.h>
#import "CBLBaseModel.h"
#import "ArticleEntity.h"

#define kTaskImageName @"image"
#define AlbumModelType @"album"
#define ImageDataContentType @"image/jpg"

@interface Album : CBLBaseModel

@property NSString *title;
@property NSArray *clips;
@property NSString *desc;

+ (Album*) getAlbumInDatabase:(CBLDatabase*) database withTitle:(NSString *)title withUUID:(NSString *)uuid;
-(void)setThumb: (UIImage*)image;
-(void)removeThumb;
-(UIImage *)getThumb;
@end
