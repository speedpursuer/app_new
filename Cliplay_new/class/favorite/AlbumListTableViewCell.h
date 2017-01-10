//
//  FavoriteListTableViewCell.h
//  Cliplay
//
//  Created by 邢磊 on 2016/11/3.
//
//

#import <UIKit/UIKit.h>
#import <LKBadgeView/LKBadgeView.h>

@interface AlbumListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet LKBadgeView *badge;
@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@end
