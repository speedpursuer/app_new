//
//  VoteView.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/2/8.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoteView : UIView
@property (weak, nonatomic) IBOutlet UILabel *desc;
- (void)setDescText:(NSString *)desc;
@end
