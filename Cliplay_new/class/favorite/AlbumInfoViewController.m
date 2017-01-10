//
//  AlbumInfoViewController.m
//  Cliplay
//
//  Created by 邢磊 on 2016/12/28.
//
//

#import "AlbumInfoViewController.h"
#import "DEComposeTextView.h"

@interface AlbumInfoViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextView;
@property (weak, nonatomic) IBOutlet DEComposeTextView *descTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@end

@implementation AlbumInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setUp];
    // Do any additional setup after loading the view.
}

- (void)setUp {
	_nameTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"名称" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
	[_descTextView setPlaceholder:@"简介"];
	[_nameTextView setText:_name];
	[_descTextView setText:_desc];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[_nameTextView becomeFirstResponder];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	[self.view endEditing:YES];
	if (sender == self.saveButton) {
		_shouldSave = YES;
		_name = _nameTextView.text;
		_desc = _descTextView.text;
	}
}

#pragma mark - Textfield changed

- (void)textChanged:(NSNotification *)notification
{
	if([[_nameTextView text] length] == 0)
	{
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	else
	{
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}
@end
