//
//  ImageEntity.h
//  Cliplay
//
//  Created by 邢磊 on 16/4/1.
//
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface ImageEntity : NSObject <CBLJSONEncoding>

//- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithURL:(NSString *)url;
- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc;
- (instancetype)initWithData:(NSString *)url desc:(NSString *)desc tag:(NSInteger)tag;
- (instancetype)initWithCopy:(ImageEntity *)entity;

@property (readwrite) NSString *desc;
@property NSString *url;
@property NSInteger tag;
@end
