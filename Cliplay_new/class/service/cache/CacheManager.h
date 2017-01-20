//
//  CacheManager.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/12.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYWebImage/YYWebImage.h>

@protocol DownloadDelegate <NSObject>
- (void)handleBackgroundDownload;
@end

@interface CacheManager : NSObject
@property (weak) id<DownloadDelegate> delegate;
+ (id)sharedManager;
- (void)stopGIFAllOprts;
- (void)requestGIFWithURL:(NSString *)url;
- (void)performBackgroundDownload;
- (UIImage *)cachedGIFWith:(NSString *)url;
- (UIImage *)createImageWithColor: (UIColor *) color;
- (NSInteger)totalCached;
- (int)getCacheLimit;
- (void)setCacheLimit:(int)limit;
- (void)deleteAllCache;
@end

@interface UIImageView (CliplayCache)
- (void)requestSImageWithURL:(NSString *)url;
- (void)requestSImageWithURL:(NSString *)url withPlaceholder:(UIImage *)image completion:(YYWebImageCompletionBlock)completion;
@end
