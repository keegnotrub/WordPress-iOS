//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "WPcomLoginViewController.h"
#import "UITableViewTextFieldCell.h"
#import "SFHFKeychainUtils.h"
#import "WordPressApi.h"
#import "WordPressComApi.h"

@interface WPcomLoginViewController () <UITextFieldDelegate>
@property (nonatomic, retain) NSString *footerText, *buttonText;
@property (nonatomic, assign) BOOL isSigningIn;
@property (nonatomic, retain) WordPressComApi *wpComApi;

- (void)signIn:(id)sender;
@end


@implementation WPcomLoginViewController {
    UITableViewTextFieldCell *loginCell, *passwordCell;
}
@synthesize footerText, buttonText, isSigningIn, isStatsInitiated;
@synthesize delegate;
@synthesize wpComApi = _wpComApi;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    self.wpComApi = [WordPressComApi sharedApi];
	self.footerText = @" ";
	self.buttonText = NSLocalizedString(@"Sign In", @"");
	self.navigationItem.title = NSLocalizedString(@"Sign In", @"");

	// Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wpcom.png";
	if(DeviceIsPad() == YES) {
		logoFile = @"logo_wpcom@2x.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	else if([[UIDevice currentDevice] platformString] == IPHONE_1G_NAMESTRING) {
		logoFile = @"logo_wpcom.png";
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
	
	if(DeviceIsPad())
		self.tableView.backgroundView = nil;

//	self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationItem setHidesBackButton:NO animated:NO];
	isSigningIn = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
		return 2;
	else
		return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return footerText;
	else
		return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	if(indexPath.section == 1) {
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}
        if(isSigningIn) {
			[activityCell.spinner startAnimating];
			self.buttonText = NSLocalizedString(@"Signing In...", @"");
		}
		else {
			[activityCell.spinner stopAnimating];
			self.buttonText = NSLocalizedString(@"Sign In", @"");
		}
		
		activityCell.textLabel.text = buttonText;
		cell = activityCell;
	} else {		
        if ([indexPath row] == 0) {
            if (loginCell == nil) {
                loginCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                            reuseIdentifier:@"TextCell"];
                loginCell.textField.text = self.wpComApi.username;
            }
            loginCell.textLabel.text = NSLocalizedString(@"Username", @"");
            loginCell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
            loginCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            loginCell.textField.returnKeyType = UIReturnKeyNext;
            loginCell.textField.tag = 0;
            loginCell.textField.delegate = self;
            if(isSigningIn)
                [loginCell.textField resignFirstResponder];
            cell = loginCell;
        }
        else {
            if (passwordCell == nil) {
                passwordCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                               reuseIdentifier:@"TextCell"];
                passwordCell.textField.text = self.wpComApi.password;
            }
            passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
            passwordCell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
            passwordCell.textField.keyboardType = UIKeyboardTypeDefault;
            passwordCell.textField.secureTextEntry = YES;
            passwordCell.textField.tag = 1;
            passwordCell.textField.delegate = self;
            if(isSigningIn)
                [passwordCell.textField resignFirstResponder];
            cell = passwordCell;
        }
    }

	return cell;    
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];
		
	switch (indexPath.section) {
		case 0:
        {
			UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:indexPath];
			for(UIView *subview in cell.subviews) {
				if([subview isKindOfClass:[UITextField class]] == YES) {
					UITextField *tempTextField = (UITextField *)subview;
					[tempTextField becomeFirstResponder];
					break;
				}
			}
			break;
        }
		case 1:
			for(int i = 0; i < 2; i++) {
				UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
				for(UIView *subview in cell.subviews) {
					if([subview isKindOfClass:[UITextField class]] == YES) {
						UITextField *tempTextField = (UITextField *)subview;
						[self textFieldDidEndEditing:tempTextField];
					}
				}
			}
			if([loginCell.textField.text isEqualToString:@""]) {
				self.footerText = NSLocalizedString(@"Username is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else if([passwordCell.textField.text isEqualToString:@""]) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else {
				self.footerText = @" ";
				self.buttonText = NSLocalizedString(@"Signing in...", @"");
				
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				if (!isSigningIn){
					[self.navigationItem setHidesBackButton:YES animated:NO];
					isSigningIn = YES;
                    [self signIn:self];
				}
			}
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	UITableViewCell *cell = nil;
    UITextField *nextField = nil;
    switch (textField.tag) {
        case 0:
            [textField endEditing:YES];
            cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            if(cell != nil) {
                nextField = (UITextField*)[cell viewWithTag:1];
                if(nextField != nil)
                    [nextField becomeFirstResponder];
            }
            break;
        case 1:
            if((![loginCell.textField.text isEqualToString:@""]) && (![passwordCell.textField.text isEqualToString:@""])) {
                if (!isSigningIn){
                    isSigningIn = YES;
					[self.navigationItem setHidesBackButton:YES animated:NO];
                    [self.tableView reloadData];
                    [self signIn:self];
                }
            }
            break;
	}

	return YES;	
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				self.footerText = NSLocalizedString(@"Username is required.", @"");
			}
			else {
				textField.text = [[textField.text stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
			}
			break;
		case 1:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
			}
			break;
		default:
			break;
	}
	
//	[self.tableView reloadData];
	[textField resignFirstResponder];
}

#pragma mark -
#pragma mark Custom methods

- (void)signIn:(id)sender {
    [self.wpComApi setUsername:loginCell.textField.text
                      password:passwordCell.textField.text
                       success:^{
                           [self.delegate loginController:self didAuthenticateWithUsername:self.wpComApi.username];
                       }
                       failure:^(NSError *error) {
                           self.footerText = NSLocalizedString(@"Sign in failed. Please try again.", @"");
                           self.buttonText = NSLocalizedString(@"Sign In", @"");
                           isSigningIn = NO;
                           [self.tableView reloadData];
                       }];
}

- (IBAction)cancel:(id)sender {
    [self.delegate loginControllerDidDismiss:self];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];    
}

- (void)viewDidUnload {
}

- (void)dealloc {
    self.footerText = nil;
    self.buttonText = nil;
    self.wpComApi = nil;
    [super dealloc];
}


@end

