//
//  Image.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/30.
//
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface Image : NSObject <CBLJSONEncoding>
@property (readwrite) NSString* desc;
@property (readwrite) NSString* url;
@end
