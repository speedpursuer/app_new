//
//  MyLBDelegate.h
//  Cliplay
//
//  Created by 邢磊 on 16/8/19.
//
//

#import <Foundation/Foundation.h>
#import "ModelComment.h"

@protocol MyLBDelegate <NSObject>
//- (void)didSubmitComment:(ModelComment *)commment hasError:(BOOL)hasError;
- (void)willPerformAction;
- (void)didPerformActionWithResult:(id)result error:(BOOL)error;
- (void)didShowLoginSelection;
- (void)didSelectLogin;
@end

@protocol CommentDelegate <MyLBDelegate>
//- (void)willShareClip;
//- (void)didShareClip:(BOOL)successful;
@end

@protocol ShareDelegate <MyLBDelegate>
//- (void)willShareClip;
//- (void)didShareClip:(BOOL)successful;
@end
