//
//  CBLBaseModel.h
//  Cliplay
//
//  Created by 邢磊 on 2016/12/13.
//
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLBaseModel : CBLModel
@property NSString *owner;

+ (NSString*) docType;
+ (NSString*) docID:(NSString *)uuid;
+ (CBLBaseModel *)getModelInDatabase:(CBLDatabase*) database withUUID:(NSString *)uuid;
- (NSString *)docID;
@end
