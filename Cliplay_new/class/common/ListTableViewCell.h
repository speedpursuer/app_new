//
//  ListTableViewCell.h
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/23.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *desc;
- (void)setCellData:(NSString *)url name:(NSString *)name desc:(NSString *)desc;
@end
