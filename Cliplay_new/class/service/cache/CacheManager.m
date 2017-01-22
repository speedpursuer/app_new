//
//  CacheManager.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/12.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CacheManager.h"
#import "Reachability.h"
#import "JDStatusBarNotification.h"

#define kOneMB (1024 * 1024)

@interface CacheManager()
@property YYWebImageManager *backgroundManager;
@property YYWebImageManager *foregroundManager;
@property YYWebImageManager *sImageManager;
@property Reachability *networkReachability;
@property UIImage *defaultPlaceholder;
- (void)requestSImageWithURL:(NSString *)url forImageView:(UIImageView *)imageView;
@end

@implementation CacheManager
dispatch_semaphore_t _lock;

+ (id)sharedManager {
	static CacheManager *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}

- (instancetype)init {
	if (self = [super init]) {
		[self setup];
		_lock = dispatch_semaphore_create(1);
	}
	return self;
}

+ (dispatch_queue_t)ManagerQueue {
	static dispatch_queue_t queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queue = dispatch_queue_create("com.lee.cliplay.cache", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
	});
	return queue;
}

#pragma mark - Initial Setup

- (void)setup {
	_foregroundManager = [YYWebImageManager sharedManager];
	[[self foregroundManager].queue setMaxConcurrentOperationCount:2];
	[[self foregroundManager] setTimeout:5];
	
	YYImageCache *sharedCache = [YYImageCache sharedCache];
	[self configCacheLimit:sharedCache.diskCache];
	
	NSOperationQueue *backGroundQueue = [NSOperationQueue new];
	backGroundQueue.maxConcurrentOperationCount = 2;
	_backgroundManager = [[YYWebImageManager alloc] initWithCache:sharedCache queue:backGroundQueue];
	[_backgroundManager setTimeout:3];
	
	YYImageCache *sImageCache = [self sImageCache];
	NSOperationQueue *queue = [NSOperationQueue new];
	_sImageManager = [[YYWebImageManager alloc] initWithCache:sImageCache queue:queue];
	
	[self observeChanges];
	
	_defaultPlaceholder = [self createImageWithColor:[UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1]];
	
//	[self cleanup];
}

- (void)configCacheLimit:(YYDiskCache *)diskCache {
	diskCache.costLimit = [self getCacheLimit] * kOneMB;
	diskCache.freeDiskSpaceLimit = 200 * kOneMB;
}

- (YYImageCache *)sImageCache {
	NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
															   NSUserDomainMask, YES) firstObject];
	cachePath = [cachePath stringByAppendingPathComponent:@"com.lee.cliplay"];
	cachePath = [cachePath stringByAppendingPathComponent:@"sImages"];
	return [[YYImageCache alloc] initWithPath:cachePath];
}

#pragma mark - Auto background download

- (void)observeChanges {
	[[self foregroundManager].queue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
	[self configReachability];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
					   context:(void *)context {
	[self performBackgroundDownload];
}

- (void)performBackgroundDownload {
	dispatch_async([CacheManager ManagerQueue], ^{
		dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
		[self cancelBackgroundOprts];
		if([self hasWifi] && _delegate && [self foregroundManager].queue.operationCount == 0) {
			[_delegate handleBackgroundDownload];
		}
//		if(_foregroundManager.queue.operationCount > 0) {
//			[self cancelBackgroundOprts];
//		}else {
//			[self cancelBackgroundOprts];
//			if([self hasWifi] && _delegate) {
//				[_delegate handleBackgroundDownload];
//			}
//		}
		dispatch_semaphore_signal(_lock);
	});
}

- (void)cancelBackgroundOprts {
	if(_backgroundManager.queue.operationCount >0) {
		[_backgroundManager.queue cancelAllOperations];
	}
}

#pragma mark - Cleanup

- (void)dealloc {
	[[self foregroundManager].queue removeObserver:self forKeyPath:@"operationCount"];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:kReachabilityChangedNotification
												  object:nil];
	[self stopGIFAllOprts];
	[_sImageManager.queue cancelAllOperations];
}

- (void)stopGIFAllOprts {
	[self cancelGIFOperations];
	[[YYImageCache sharedCache].memoryCache removeAllObjects];
//	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)cancelGIFOperations {
	[[self foregroundManager].queue cancelAllOperations];
	[_backgroundManager.queue cancelAllOperations];
}

//For test
- (void)cleanup {
	[[YYImageCache sharedCache].diskCache removeAllObjects];
	[_sImageManager.cache.diskCache removeAllObjects];
}

#pragma mark - Request remote/cached image
- (void)requestGIFWithURL:(NSString *)url {
	if(![[YYImageCache sharedCache] containsImageForKey:url withType:YYImageCacheTypeDisk]){
		[_backgroundManager requestImageWithURL:[NSURL URLWithString:url]
										options:YYWebImageOptionShowNetworkActivity
									   progress:nil
									  transform:nil
									 completion:nil];
	}
}

- (void)requestSImageWithURL:(NSString *)url forImageView:(UIImageView *)imageView{
	 [imageView yy_setImageWithURL:[NSURL URLWithString: url]
					   placeholder:_defaultPlaceholder
						   options:YYWebImageOptionSetImageWithFadeAnimation
						   manager:_sImageManager
						  progress:nil
						 transform:nil
						completion:nil
	];
}

- (void)requestSImageWithURL:(NSString *)url forImageView:(UIImageView *)imageView withPlaceholder:(UIImage *)image{
	[imageView yy_setImageWithURL:[NSURL URLWithString: url]
					  placeholder:image
						  options:kNilOptions
						  manager:_sImageManager
						 progress:nil
						transform:nil
					   completion:nil
	 ];
}

- (void)requestSImageWithURL:(NSString *)url forImageView:(UIImageView *)imageView withPlaceholder:(UIImage *)image completion:(YYWebImageCompletionBlock)completion{
	[imageView yy_setImageWithURL:[NSURL URLWithString: url]
					  placeholder:image
						  options:kNilOptions
						  manager:_sImageManager
						 progress:nil
						transform:nil
					   completion:completion
	 ];
}

- (UIImage *)cachedGIFWith:(NSString *)url {
	return [[YYImageCache sharedCache] getImageForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:url]]];
}

#pragma mark - Cache Settings
- (void)setCacheLimit:(int)limit {
	Configuration *config = [Configuration load];
	config.cacheLimit = [NSNumber numberWithInt:limit];
	[config save];
	[[YYImageCache sharedCache].diskCache setCostLimit:limit * kOneMB];
	[[YYImageCache sharedCache].diskCache trimToCost:limit * kOneMB];
	[self showSuccessMessage:NSLocalizedString(@"Successfully Saved", @"cache setup")];
}

- (int)getCacheLimit {
	Configuration *config = [Configuration load];
	return [config.cacheLimit intValue];
}

- (NSInteger)totalCached {
	return [YYImageCache sharedCache].diskCache.totalCost / kOneMB;
}

- (void)deleteAllCache {
	[[YYImageCache sharedCache].diskCache removeAllObjects];
	[self showSuccessMessage:NSLocalizedString(@"All Cached Removed", @"cache setup")];
}

#pragma mark - Helper

-(UIImage *)createImageWithColor: (UIColor *) color {
	CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	
	UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return theImage;
}

- (void)showSuccessMessage:(NSString *)message {
	[JDStatusBarNotification showWithStatus:message dismissAfter:2.0 styleName:JDStatusBarStyleSuccess];
}

#pragma mark - Reachability
- (void)configReachability {
	_networkReachability = [Reachability reachabilityForInternetConnection];
	_networkReachability.reachableOnWWAN = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reachabilityChanged)
												 name:kReachabilityChangedNotification
											   object:nil];
	
	[_networkReachability startNotifier];
}

- (void)reachabilityChanged {
	[self performBackgroundDownload];
}

- (BOOL)hasWifi {
	return [_networkReachability currentReachabilityStatus] == ReachableViaWiFi? YES: NO;
}

@end

@implementation UIImageView (CliplayCache)
- (void)requestSImageWithURL:(NSString *)url {
	[[CacheManager sharedManager] requestSImageWithURL:url forImageView:self];
}

- (void)requestSImageWithURL:(NSString *)url withPlaceholder:(UIImage *)image completion:(YYWebImageCompletionBlock)completion{
	[[CacheManager sharedManager] requestSImageWithURL:url forImageView:self withPlaceholder:image completion:completion];
}

@end
