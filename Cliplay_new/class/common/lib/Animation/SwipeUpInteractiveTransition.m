//
//  SwipeUpInteractiveTransition.m
//  Pods
//
//  Created by 纪洪波 on 16/3/17.
//
//

#import "SwipeUpInteractiveTransition.h"

#define kMargin 30
#define kMinDismissY 50

@implementation SwipeUpInteractiveTransition
- (instancetype)init:(ClipPlayController *)vc
{
    self = [super init];
    if (self) {
        _vc = vc;
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureHandler:)];
        [vc.view addGestureRecognizer:pan];
    }
    return self;
}

- (void)panGestureHandler:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:gesture.view];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _isInteracting = YES;
            [_vc dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case UIGestureRecognizerStateChanged: {
			if(fabs(translation.y) > kMinDismissY) {
				if(!_vc.isInLandscapeMode && translation.y > kMinDismissY) {
					CGFloat fraction = (translation.y / 400);
					fraction = fmin(fmaxf(fraction, 0.0), 1.0);
					_shouldComplete = fraction > 0.3;
					[self updateInteractiveTransition:fraction];
				}
			}else {
				__weak typeof(self) _self = self;
				[_self adjustProgressWithGesture:gesture];
			}
            break;
        }
        case UIGestureRecognizerStateEnded: {
            _isInteracting = NO;
            if (!_shouldComplete || gesture.state == UIGestureRecognizerStateCancelled) {
                [self cancelInteractiveTransition];
            }else {
                [self finishInteractiveTransition];
            }
            break;
        }
        default:
            break;
    }
}

- (void)adjustProgressWithGesture:(UIPanGestureRecognizer *)gesture {
	
	YYAnimatedImageView *imageView = self.vc.imageView;
	UIImage<YYAnimatedImage> *image = (id)imageView.image;
	
	if ([image conformsToProtocol:@protocol(YYAnimatedImage)]) {
		CGPoint p = [gesture locationInView:gesture.view];
		CGFloat progress = 0;
		if(p.x < kMargin || p.x > gesture.view.frame.size.width - kMargin) {
			return;
		}else{
			[imageView stopAnimating];
			progress = (p.x - kMargin) / (gesture.view.frame.size.width - kMargin * 2);
			imageView.currentAnimatedImageIndex = image.animatedImageFrameCount * progress;
		}
	}
}

//- (void)panGestureHandler:(UIPanGestureRecognizer *)gesture {
//	CGPoint translation = [gesture translationInView:gesture.view];
//	switch (gesture.state) {
//		case UIGestureRecognizerStateBegan: {
//			_isInteracting = YES;
//			[_vc dismissViewControllerAnimated:YES completion:nil];
//			break;
//		}
//		case UIGestureRecognizerStateChanged: {
//			CGFloat fraction = (translation.y / 400);
//			fraction = fmin(fmaxf(fraction, 0.0), 1.0);
//			_shouldComplete = fraction > 0.5;
//			[self updateInteractiveTransition:fraction];
//			break;
//		}
//		case UIGestureRecognizerStateEnded: {
//			_isInteracting = NO;
//			if (!_shouldComplete || gesture.state == UIGestureRecognizerStateCancelled) {
//				[self cancelInteractiveTransition];
//			}else {
//				[self finishInteractiveTransition];
//			}
//			break;
//		}
//		default:
//			break;
//	}
//}
@end
