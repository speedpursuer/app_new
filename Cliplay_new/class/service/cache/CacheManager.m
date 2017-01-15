//
//  CacheManager.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/12.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "CacheManager.h"
#import "Reachability.h"

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

#pragma mark - Initial Setup

- (void)setup {
	_foregroundManager = [YYWebImageManager sharedManager];
	[_foregroundManager.queue setMaxConcurrentOperationCount:1];
	
	YYImageCache *sharedCache = [YYImageCache sharedCache];
	NSOperationQueue *backGroundQueue = [NSOperationQueue new];
	backGroundQueue.maxConcurrentOperationCount = 1;
	_backgroundManager = [[YYWebImageManager alloc] initWithCache:sharedCache queue:backGroundQueue];
	
	YYImageCache *sImageCache = [self sImageCache];
	NSOperationQueue *queue = [NSOperationQueue new];
	_sImageManager = [[YYWebImageManager alloc] initWithCache:sImageCache queue:queue];
	
	[self observeChanges];
	
	_defaultPlaceholder = [self createImageWithColor:[UIColor colorWithRed:228.0/255.0 green:228.0/255.0 blue:228.0/255.0 alpha:1]];
	
	[self cleanup];
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
	[_foregroundManager.queue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
	[self configReachability];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
					   context:(void *)context {
	[self performBackgroundDownload];
}

- (void)performBackgroundDownload {
	dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
	if(_foregroundManager.queue.operationCount > 0) {
		[self cancelBackgroundOprts];
	}else {
		[self cancelBackgroundOprts];
		if([self hasWifi]) {
			[_delegate handleGIFFetch];
		}
	}
	dispatch_semaphore_signal(_lock);
}

- (void)cancelBackgroundOprts {
	if(_backgroundManager.queue.operationCount >0) {
		[_backgroundManager.queue cancelAllOperations];
	}
}

#pragma mark - Cleanup

- (void)dealloc {
	[_foregroundManager.queue removeObserver:self forKeyPath:@"operationCount"];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:kReachabilityChangedNotification
												  object:nil];
	[self stopGIFAllOprts];
	[_sImageManager.queue cancelAllOperations];
}

- (void)stopGIFAllOprts {
	[self cancelGIFOperations];
	[[YYImageCache sharedCache].memoryCache removeAllObjects];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)cancelGIFOperations {
	[_foregroundManager.queue cancelAllOperations];
	[_backgroundManager.queue cancelAllOperations];
}

//For test
- (void)cleanup {
	[[YYImageCache sharedCache].diskCache removeAllObjects];
	[_sImageManager.cache.diskCache removeAllObjects];
}

#pragma mark - Request remote/cached image
- (void)requestGIFWithURL:(NSString *)url {
	if(![[YYImageCache sharedCache] containsImageForKey:url]){
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
						   options:YYWebImageOptionProgressiveBlur
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

- (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
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
