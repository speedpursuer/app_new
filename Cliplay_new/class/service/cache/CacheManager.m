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
@property BOOL hasWifi;
- (void)requestSImageWithURL:(NSString *)url forImageView:(UIImageView *)imageView;
@end

@implementation CacheManager

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
	}
	return self;
}

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
	
//	[self cleanup];
	
	[self observeChanges];
}

- (void)cleanup {
	[[YYImageCache sharedCache].diskCache removeAllObjects];
	[_sImageManager.cache.diskCache removeAllObjects];
}

- (YYImageCache *)sImageCache {
	NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
															   NSUserDomainMask, YES) firstObject];
	cachePath = [cachePath stringByAppendingPathComponent:@"com.lee.cliplay"];
	cachePath = [cachePath stringByAppendingPathComponent:@"sImages"];
	
	return [[YYImageCache alloc] initWithPath:cachePath];
}

- (NSInteger)foregroundOprtsCount {
	return _foregroundManager.queue.operationCount;
}

- (void)stopGIFAllOprts {
	[self cancelGIFOperations];
	[[YYImageCache sharedCache].memoryCache removeAllObjects];
}

- (void)cancelGIFOperations {
	[_foregroundManager.queue cancelAllOperations];
	[_backgroundManager.queue cancelAllOperations];
}

- (void)performBackgroundDownload:(BOOL)shouldStopCurrentBackgroundDownload {
	if(_foregroundManager.queue.operationCount > 0) {
		[_backgroundManager.queue cancelAllOperations];
	}else {
		if(shouldStopCurrentBackgroundDownload) {
			[_backgroundManager.queue cancelAllOperations];
		}
		if(_hasWifi) {
			[_delegate handleGIFFetch];
		}
	}
}

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
					   placeholder:nil
						   options:kNilOptions
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

- (void)observeChanges {
	[self checkWifiConnection];
	
	[_foregroundManager.queue addObserver:self forKeyPath:@"operationCount" options:0 context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(checkNetworkStatus:)
												 name:kReachabilityChangedNotification
											   object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
					   context:(void *)context {	
	[self performBackgroundDownload:NO];
}

- (void)checkNetworkStatus:(NSNotification*)note{
	[self checkWifiConnection];
}

- (void)checkWifiConnection {
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	if (networkStatus == ReachableViaWiFi) {
		_hasWifi = YES;
	}else{
		_hasWifi = NO;
	}
}

- (UIImage *)cachedGIFWith:(NSString *)url {
	return [[YYImageCache sharedCache] getImageForKey:[[YYWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:url]]];
}

- (void)dealloc {
	[_foregroundManager.queue removeObserver:self forKeyPath:@"operationCount"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	[self stopGIFAllOprts];
	[_sImageManager.queue cancelAllOperations];
}

@end

@implementation UIImageView (CliplayCache)
- (void)requestSImageWithURL:(NSString *)url {
	[[CacheManager sharedManager] requestSImageWithURL:url forImageView:self];
}

- (void)requestSImageWithURL:(NSString *)url withPlaceholder:(UIImage *)image {
	[[CacheManager sharedManager] requestSImageWithURL:url forImageView:self withPlaceholder:image];
}

- (void)requestSImageWithURL:(NSString *)url withPlaceholder:(UIImage *)image completion:(YYWebImageCompletionBlock)completion{
	[[CacheManager sharedManager] requestSImageWithURL:url forImageView:self withPlaceholder:image completion:completion];
}

@end
