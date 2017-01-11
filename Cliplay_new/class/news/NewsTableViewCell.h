//
//  NewsTableViewCell.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/9.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YYWebImage/YYWebImage.h>

@interface NewsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *shortDesc;
@property (weak, nonatomic) IBOutlet UILabel *longDesc;

- (void)setCellData:(NSString *)url name:(NSString *)name desc:(NSString *)desc;
@end
