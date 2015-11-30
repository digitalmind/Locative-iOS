//
//  GFSettingsViewController.m
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "GFSettingsViewController.h"
#import "GFGeofencesViewController.h"
#import <INTULocationManager/INTULocationManager.h>
#import <PSTAlertController/PSTAlertController.h>

@interface GFSettingsViewController () <UITextFieldDelegate, MFMailComposeViewControllerDelegate>
{
    IBOutlet UITextField *_httpUrlTextField;
    IBOutlet UISegmentedControl *_httpMethodSegmentedControl;
    
    IBOutlet UISwitch *_httpBasicAuthSwitch;
    IBOutlet UITextField *_httpBasicAuthUsernameTextField;
    IBOutlet UITextField *_httpBasicAuthPasswordTextField;

    IBOutlet UISwitch *_notifyOnSuccessSwitch;
    IBOutlet UISwitch *_notifyOnFailureSwitch;
    IBOutlet UISwitch *_soundOnNotificationSwitch;
    
    // My Geofancy
    IBOutlet UITextField *_myGfUsername;
    IBOutlet UITextField *_myGfPassword;
    IBOutlet UIButton *_myGfLoginButton;
    IBOutlet UIButton *_myGfCreateAccountButton;
    IBOutlet UIButton *_myGfLostPwButton;
    
    GFSettings *_settings;
    GFAppDelegate *_appDelegate;
}
@end

@implementation GFSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _appDelegate = (GFAppDelegate *)[[UIApplication sharedApplication] delegate];
    _settings = _appDelegate.settings;
    
    /*
     Drawer Menu Shadow
     */
    self.parentViewController.view.layer.shadowOpacity = 0.75f;
    self.parentViewController.view.layer.shadowRadius = 10.0f;
    self.parentViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [_httpUrlTextField setText:([[[_settings globalUrl] absoluteString] length] > 0)?[[_settings globalUrl] absoluteString]:nil];
    [_httpMethodSegmentedControl setSelectedSegmentIndex:[[_settings globalHttpMethod] intValue]];
    
    _httpBasicAuthSwitch.on = [[_settings httpBasicAuthEnabled] boolValue];
    [_httpBasicAuthUsernameTextField setEnabled:_httpBasicAuthSwitch.on];
    [_httpBasicAuthPasswordTextField setEnabled:_httpBasicAuthSwitch.on];
    [_httpBasicAuthUsernameTextField setText:([[_settings httpBasicAuthUsername] length] > 0)?[_settings httpBasicAuthUsername]:nil];
    [_httpBasicAuthPasswordTextField setText:([[_settings httpBasicAuthPassword] length] > 0)?[_settings httpBasicAuthPassword]:nil];
    
    _notifyOnSuccessSwitch.on = [[_settings notifyOnSuccess] boolValue];
    _notifyOnFailureSwitch.on = [[_settings notifyOnFailure] boolValue];
    _soundOnNotificationSwitch.on = [[_settings soundOnNotification] boolValue];

    [[_appDelegate cloudManager] validateSessionWithCallback:^(BOOL valid) {
        if (valid) {
            _myGfCreateAccountButton.hidden = YES;
            _myGfLostPwButton.hidden = YES;
            _myGfLoginButton.hidden = YES;
        }
        [[self tableView] reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIUserNotificationType types = (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if (indexPath.row >= 0 && indexPath.row < 5) {
            if ([[_appDelegate.settings apiToken] length] == 0) {
                return [super tableView:tableView heightForRowAtIndexPath:indexPath];
            } else {
                return 0.0f;
            }
        } else if (indexPath.row >= 5) {
            if ([[_appDelegate.settings apiToken] length] == 0) {
                return 0.0f;
            } else {
                return [super tableView:tableView heightForRowAtIndexPath:indexPath];
            }
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - TextField Delegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Helpers
- (AFSecurityPolicy *) commonPolicy {
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];
    return policy;
}

#pragma mark - IBActions
- (IBAction)saveSettings:(id)sender {
    // Normalize URL if necessary
    if ([[_httpUrlTextField text] length] > 0) {
        if([[[_httpUrlTextField text] lowercaseString] hasPrefix:@"http://"] || [[[_httpUrlTextField text] lowercaseString] hasPrefix:@"https://"]) {
            [_settings setGlobalUrl:[NSURL URLWithString:[_httpUrlTextField text]]];
        } else {
            [_settings setGlobalUrl:[NSURL URLWithString:[@"http://" stringByAppendingString:[_httpUrlTextField text]]]];
        }
    } else {
        [_settings setGlobalUrl:nil];
    }
    
    [_settings setHttpBasicAuthUsername:[_httpBasicAuthUsernameTextField text]];
    [_settings setHttpBasicAuthPassword:[_httpBasicAuthPasswordTextField text]];
    
    [_settings setGlobalHttpMethod:[NSNumber numberWithInteger:[_httpMethodSegmentedControl selectedSegmentIndex]]];
    [_settings setNotifyOnSuccess:[NSNumber numberWithBool:_notifyOnSuccessSwitch.on]];
    [_settings setNotifyOnFailure:[NSNumber numberWithBool:_notifyOnFailureSwitch.on]];
    [_settings setSoundOnNotification:[NSNumber numberWithBool:_soundOnNotificationSwitch.on]];
    
    [_settings persist];

    [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"GeofencesNav"] animated:YES completion:nil];
}

- (IBAction)toggleHttpBasicAuth:(id)sender {
    [_settings setHttpBasicAuthEnabled:[NSNumber numberWithBool:_httpBasicAuthSwitch.on]];
    [_httpBasicAuthUsernameTextField setEnabled:_httpBasicAuthSwitch.on];
    [_httpBasicAuthPasswordTextField setEnabled:_httpBasicAuthSwitch.on];
}

- (IBAction) toogleNotificationSettings:(id)sender {
    [_settings setNotifyOnSuccess:[NSNumber numberWithBool:_notifyOnSuccessSwitch.on]];
    [_settings setNotifyOnFailure:[NSNumber numberWithBool:_notifyOnFailureSwitch.on]];
    [_settings setSoundOnNotification:[NSNumber numberWithBool:_soundOnNotificationSwitch.on]];
}

- (IBAction) sendTestRequest:(id)sender {
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyRoom
                                                                     timeout:10.0
                                                        delayUntilAuthorized:YES
                                                                       block:
     ^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
         NSString *url = [_httpUrlTextField text];
         NSString *eventId = [[NSUUID UUID] UUIDString];
         NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
         NSDate *timestamp = [NSDate date];
         
         NSDictionary *parameters = @{@"id":eventId,
                                      @"trigger":@"test",
                                      @"device":deviceId,
                                      @"latitude":currentLocation?[NSNumber numberWithFloat:currentLocation.coordinate.latitude]:@123.00,
                                      @"longitude":currentLocation?[NSNumber numberWithFloat:currentLocation.coordinate.longitude]:@123.0f,
                                      @"timestamp": [NSString stringWithFormat:@"%f", [timestamp timeIntervalSince1970]]};
         
         GFRequest *httpRequest = [GFRequest create];
         httpRequest.url = url;
         httpRequest.method = ([_httpMethodSegmentedControl selectedSegmentIndex] == 0)?@"POST":@"GET";
         httpRequest.parameters = parameters;
         httpRequest.eventType = [NSNumber numberWithInt:0];
         httpRequest.timestamp = timestamp;
         httpRequest.uuid = [[NSUUID UUID] UUIDString];
         
         if ([_settings httpBasicAuthEnabled]) {
             httpRequest.httpAuth = [NSNumber numberWithBool:YES];
             httpRequest.httpAuthUsername = [_settings httpBasicAuthUsername];
             httpRequest.httpAuthPassword = [_settings httpBasicAuthPassword];
         }
         
         [httpRequest save];
         [_appDelegate.requestManager flushWithCompletion:nil];
    }];
    
    PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"A Test-Request has been sent. The result will be dispalyed as soon as it's succeeded / failed.", nil)
                                                                   preferredStyle:PSTAlertControllerStyleAlert];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleDefault handler:nil]];
    [controller showWithSender:sender controller:self animated:YES completion:nil];
}

#pragma mark - IBActions
- (IBAction) toggleMenu:(id)sender {
    [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen animated:YES allowUserInterruption:YES completion:nil];
}

- (IBAction) loginToAccount:(id)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    [[_appDelegate cloudManager] loginToAccountWithUsername:[_myGfUsername text] andPassword:[_myGfPassword text] onFinish:^(NSError *error, NSString *sessionId) {
        
        [SVProgressHUD dismiss];
        
        _myGfCreateAccountButton.hidden = !error;
        _myGfLostPwButton.hidden = !error;
        _myGfLoginButton.hidden = !error;
        
        if (!error) {
            [_appDelegate.settings setApiToken:sessionId];
            [_appDelegate.settings persist];
            [[self tableView] reloadData];
        }
        
        PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:error ? NSLocalizedString(@"Error", nil) : NSLocalizedString(@"Success", nil)
                                                                              message:error ? NSLocalizedString(@"There has been a problem with your login, please try again!", nil) : NSLocalizedString(@"Login successful! Your triggered geofences will now be visible in you Account at http://my.locative.io!", nil)
                                                                       preferredStyle:PSTAlertControllerStyleAlert];
        [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleDefault handler:nil]];
        [controller showWithSender:sender controller:self animated:YES completion:nil];
    }];
}

- (IBAction) recoverMyGfPassword:(id)sender {
    PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"This will open up Safari and lead you to the password recovery website. Sure?", nil)
                                                                   preferredStyle:PSTAlertControllerStyleAlert];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:PSTAlertActionStyleDefault handler:nil]];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://my.locative.io/youforgot"]];
    }]];
    [controller showWithSender:sender controller:self animated:YES completion:nil];
}

- (IBAction) logout:(id)sender
{
    [_appDelegate.settings removeApiToken];
    
    _myGfCreateAccountButton.hidden = NO;
    _myGfLostPwButton.hidden = NO;
    _myGfLoginButton.hidden = NO;
    [[self tableView] reloadData];
}

- (IBAction) exportAsGpx:(id)sender {
    PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"Your Geofences (no iBeacons) will be exported as an ordinary GPX file, only location and UUID/Name as well as Description will be exported. Custom settings like radius and URLs will fall back to default.", nil)
                                                                   preferredStyle:PSTAlertControllerStyleAlert];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [self performExportGpx];
    }]];
    [controller showWithSender:sender controller:self animated:YES completion:nil];
}

- (void) performExportGpx {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    GPXRoot *root = [GPXRoot rootWithCreator:@"Geofancy"];
    __block NSString *gpx = @"";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *geofences = [GFGeofence all];
        for (GFGeofence *geofence in geofences) {
            if ([geofence.type intValue] == GFGeofenceTypeGeofence) {
                GPXWaypoint *waypoint = [GPXWaypoint waypointWithLatitude:[geofence.latitude floatValue] longitude:[geofence.longitude floatValue]];
                waypoint.name = ([geofence.customId length] > 0)?geofence.customId:geofence.uuid;
                waypoint.comment = geofence.name;
                [root addWaypoint:waypoint];
            }
        }
        NSLog(@"GPX String: %@", gpx);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            gpx = [root gpx];
            [SVProgressHUD dismiss];
            [self sendMailContainingGpxContent:gpx];
        });
    });
}

- (void) sendMailContainingGpxContent:(NSString *)gpx {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:NSLocalizedString(@"My Geofancy Backup", nil)];
        [mailViewController addAttachmentData:[gpx dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/xml" fileName:@"Geofences.gpx"];
        [self presentViewController:mailViewController animated:YES completion:nil];
    } else {
        PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                              message:NSLocalizedString(@"You need to setup an Email account. Go to your device's settings into the mail section.", nil)
                                                                       preferredStyle:PSTAlertControllerStyleAlert];
        [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleDefault handler:nil]];
        [controller showWithSender:nil controller:self animated:YES completion:nil];
    }
}

#pragma mark - MailComposeViewController Delegate
- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
