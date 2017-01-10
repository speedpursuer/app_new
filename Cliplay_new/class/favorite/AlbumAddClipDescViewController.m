//
//  AlbumAddClipDescViewController.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/26.
//
//

#import "AlbumAddClipDescViewController.h"
#import <YYWebImage/YYWebImage.h>

@interface AlbumAddClipDescViewController ()
@property (weak, nonatomic) IBOutlet YYAnimatedImageView *thumb;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

@implementation AlbumAddClipDescViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadUI];
	[self setData];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadUI {
	[self loadThumb];
	[_desc setPlaceholder:@"请输入描述..."];
	[_desc becomeFirstResponder];
	_thumb.contentMode = UIViewContentModeScaleAspectFill;
	_thumb.layer.masksToBounds = YES;
}

- (void)setData {
	if(_currDesc) {
		_desc.text = _currDesc;
	}
}

- (void)loadThumb {
	_thumb.autoPlayAnimatedImage = YES;
	[_thumb yy_setImageWithURL:[NSURL URLWithString:_url] placeholder:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	[self.view endEditing:YES];
	if (sender == self.saveButton) {
		_shouldSave = YES;
	}
}

@end
