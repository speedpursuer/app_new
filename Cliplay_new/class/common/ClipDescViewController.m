//
//  ClipDescViewController.m
//  Cliplay_new
//
//  Created by 邢磊 on 2017/1/21.
//  Copyright © 2017年 邢磊. All rights reserved.
//

#import "ClipDescViewController.h"

@interface ClipDescViewController ()
@property (weak, nonatomic) IBOutlet DEComposeTextView *descView;
@property (weak, nonatomic) IBOutlet YYAnimatedImageView *thumbView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *confirmButton;

@end

@implementation ClipDescViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadUI];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadUI {
	[self setupThumb];
	[self setupDesc];
	[self setupButton];
	[self setupTitle];
}

- (void)setupDesc {
	if(_desc) {
		_descView.text = _desc;
	}
	if(_actionType == sendClip) {
		_descView.keyboardType = UIKeyboardTypeTwitter;
	}
	[_descView setPlaceholder:_descPlaceholder];
	[_descView becomeFirstResponder];
}

- (void)setupThumb {
	_thumbView.contentMode = UIViewContentModeScaleAspectFill;
	_thumbView.layer.masksToBounds = YES;
	_thumbView.autoPlayAnimatedImage = YES;
	[_thumbView yy_setImageWithURL:[NSURL URLWithString:_url] placeholder:nil];
}

- (void)setupButton {
	if(_actionType == sendClip) {
		_confirmButton.title = @"Send";
	}else{
		_confirmButton.title = @"Save";
	}
}

- (void)setupTitle {
	if(_actionType == sendClip) {
		self.title = @"Share to Weibo";
	}else if(_actionType == editDesc) {
		self.title = @"Edit Desc";
	}else {
		self.title = @"Add Desc";
	}
}

- (IBAction)goBack:(id)sender {
	[self.view endEditing:YES];
	if(sender == self.confirmButton) {
		if(_actionType == sendClip) {
			[_delegate sendClip:_url desc:_descView.text];
		}else{
			[_delegate saveDesc:_descView.text];
		}
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
