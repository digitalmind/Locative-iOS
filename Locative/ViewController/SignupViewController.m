#import "Locative-Swift.h"
#import "CloudManager.h"
#import "SignupViewController.h"

@import SVProgressHUD;

@interface SignupViewController ()

@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;

@property (nonatomic, weak) AppDelegate *appDelegate;
@end

@implementation SignupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.usernameTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction) signupAccount:(id)sender {
    if ([[self.usernameTextField text] length] > 4 ||
        [[self.emailTextField text] length] > 4 ||
        [[self.passwordTextField text] length] > 4) {
        
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

        CloudCredentials *credentials = [[CloudCredentials alloc] initWithUsername:[self.usernameTextField text]
                                                                             email:[self.emailTextField text]
                                                                          password:[self.passwordTextField text]];
        
        [[_appDelegate cloudManager] signupAccountWithCredentials:credentials onFinish:^(NSError *error, CloudManagerSignupError gfcError) {
            
            [SVProgressHUD dismiss];
            
            if (!error) {
                // Account created successfully!
                
                [[_appDelegate cloudManager] loginToAccountWithCredentials:credentials onFinish:^(NSError *error, NSString *sessionId) {
                    if (!error) {
                        [self.appDelegate.settings setApiToken:sessionId];
                        [self.appDelegate.settings persist];
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                                   message:NSLocalizedString(@"Your account has been created successfully! You have been logged in automatically.", nil)
                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[self navigationController] popViewControllerAnimated:YES];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                        
                    } else {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                                   message:NSLocalizedString(@"Your account has been created successfully! You may now sign in using the prvoided credentials.", nil)
                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[self navigationController] popViewControllerAnimated:YES];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
                
                
            } else if (gfcError == CloudManagerSignupErrorUserExisting) {
                // User already existing
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                                           message:NSLocalizedString(@"A user with the same Username / E-Mail address ist already existing. Please choose another one..", nil)
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                   message:NSLocalizedString(@"Please enter a Username and a Password which have a minimum of 5 chars.", nil)
                                                                            preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction) readTos:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                               message:NSLocalizedString(@"This will open up Safari and lead to our TOS. Sure?", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://my.locative.io/legal"]];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
