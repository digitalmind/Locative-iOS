#import "Locative-Swift.h"
#import "AddEditGeofenceViewController.h"
#import "CloudManager.h"
#import "MKMapView+ZoomLevel.h"

@import MapKit;
@import SVProgressHUD;
@import ObjectiveRecord;

typedef NS_ENUM(NSInteger, AlertViewType) {
    AlertViewTypeLocationEnter = 1000
};

@interface AddEditGeofenceViewController () <MKMapViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate>
{
    IBOutlet MKMapView *_mapView;
    IBOutlet UISlider *_radiusSlider;
    IBOutlet UISwitch *_enterSwitch;
    IBOutlet UISwitch *_exitSwitch;
    IBOutlet UISegmentedControl *_typeSegmentedControl;
    IBOutlet UIButton *_locationButton;
    
    IBOutlet UITextField *_customLocationId;
    IBOutlet UITextField *_enterUrlTextField;
    IBOutlet UITextField *_exitUrlTextField;
    
    IBOutlet UIButton *_enterMethod;
    IBOutlet UIButton *_exitMethod;
    
    IBOutlet UISwitch *_httpAuthSwitch;
    IBOutlet UITextField *_httpUsernameTextField;
    IBOutlet UITextField *_httpPasswordTextField;
    
    IBOutlet UITextField *_iBeaconUuidTextField;
    IBOutlet UITextField *_iBeaconMinorTextField;
    IBOutlet UITextField *_iBeaconMajorTextField;
    IBOutlet UITextField *_iBeaconCustomId;
    IBOutlet UIPickerView *_iBeaconPicker;
    
    IBOutlet UIButton *_backupButton;
    
    BOOL _viewAppeared;
    BOOL _gotCurrentLocation;
    MKCircle *_radialCircle;
    CLLocation *_location;
    GeofenceType _geofenceType;
    AppDelegate *_appDelegate;
    NSMutableArray *_iBeaconPresets;
    CLGeocoder *_geocoder;
}

@property (nonatomic, strong) NSNumberFormatter *majorMinorFormatter;

@end

@implementation AddEditGeofenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Fixes UI glitch which leads to UISegmentedControl being shown slightly above map when editing exiting Geofence/iBeacon
    if (self.event) {
        _typeSegmentedControl.hidden = YES;
    }
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _iBeaconPicker.hidden = YES;
    _geocoder = [[CLGeocoder alloc] init];
    [self setupBeaconPresets];
}

- (void)setupBeaconPresets {
    _iBeaconPresets = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"iBeaconPresets" ofType:@"plist"]];
    [_iBeaconPresets sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"name"] caseInsensitiveCompare:obj2[@"name"]];
    }];
    [_iBeaconPresets insertObject:@{@"name": NSLocalizedString(@"No iBeacon Preset", @"No iBeacon Preset at UIPickerView")} atIndex:0];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(_viewAppeared) {
        return;
    }
    
    if(self.event)
    {
        _geofenceType = [self.event.type intValue];
        
        if (_geofenceType == GeofenceTypeGeofence) {
            _location = [[CLLocation alloc] initWithLatitude:[self.event.latitude doubleValue] longitude:[self.event.longitude doubleValue]];

            NSLog(@"RADIUS: %f", [self.event.radius doubleValue]);
            _radiusSlider.value = [self.event.radius doubleValue];
            _customLocationId.text = [self.event customId];
            
            [self setupLocation:_location];
            [_locationButton setTitle:self.event.name forState:UIControlStateNormal];
            [self reverseGeocodeForNearestPlacemark:^(CLPlacemark *placemark) {
                [_locationButton setTitle:[self addressFromPlacemark:placemark] forState:UIControlStateNormal];
                _gotCurrentLocation = YES;
            }];

        } else {
            _iBeaconUuidTextField.text = self.event.iBeaconUuid;
            _iBeaconCustomId.text = self.event.customId;
            _iBeaconMajorTextField.text = [NSString stringWithFormat:@"%lld", [self.event.iBeaconMajor longLongValue]];
            _iBeaconMinorTextField.text = [NSString stringWithFormat:@"%lld", [self.event.iBeaconMinor longLongValue]];
            _iBeaconPicker.hidden = NO;
            _typeSegmentedControl.hidden = YES;
        }
        
        _enterSwitch.on = ([self.event.triggers intValue] & TriggerEnter);
        _exitSwitch.on = ([self.event.triggers intValue] & TriggerExit);
        
        _enterUrlTextField.text = self.event.enterUrl;
        _exitUrlTextField.text = self.event.exitUrl;
        
        [_enterMethod setTitle:([self.event.enterMethod intValue] == 0)?@"POST":@"GET" forState:UIControlStateNormal];
        [_exitMethod setTitle:([self.event.exitMethod intValue] == 0)?@"POST":@"GET" forState:UIControlStateNormal];
        
        
        /*
         HTTP Basic Auth
         */
        _httpAuthSwitch.on = [self.event.httpAuth boolValue];
        [_httpUsernameTextField setEnabled:_httpAuthSwitch.on];
        [_httpPasswordTextField setEnabled:_httpAuthSwitch.on];
        _httpUsernameTextField.text = [self.event httpUser];
        _httpPasswordTextField.text = [self.event httpPasswordSecure];
        
        [self setTitle:self.event.name];
    }
    else
    {
        [self setTitle:NSLocalizedString(@"New Fence", @"Title for new Geofence Screen.")];
        
        [_enterMethod setTitle:([_appDelegate.settings globalHttpMethod] == 0)?@"POST":@"GET" forState:UIControlStateNormal];
        [_exitMethod setTitle:([_appDelegate.settings globalHttpMethod] == 0)?@"POST":@"GET" forState:UIControlStateNormal];
        
        _iBeaconUuidTextField.text = [[NSUUID UUID] UUIDString];
        _typeSegmentedControl.hidden = NO;
    }
    
    if([[_enterUrlTextField text] length] == 0)
    {
        if([[[_appDelegate.settings globalUrl] absoluteString] length] > 0)
        {
            _enterUrlTextField.placeholder = [_appDelegate.settings globalUrl].absoluteString;
        }
        else
        {
            _enterUrlTextField.placeholder = NSLocalizedString(@"Please configure your global url", nil);
        }
    }
    
    if([[_exitUrlTextField text] length] == 0)
    {
        if([[[_appDelegate.settings globalUrl] absoluteString] length] > 0)
        {
            _exitUrlTextField.placeholder = [_appDelegate.settings globalUrl].absoluteString;
        }
        else
        {
            _exitUrlTextField.placeholder = NSLocalizedString(@"Please configure your global url", nil);
        }
    }
    
    [self determineWetherToShowBackupButton];
}

- (void)determineWetherToShowBackupButton
{
    // Backup Button
    if (self.event) {
        if (self.event.type.integerValue == GeofenceTypeGeofence) {
            [_backupButton setHidden:NO];
            return;
        }
    }
    [_backupButton setHidden:YES];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_viewAppeared) {
        return;
    }
    
    _viewAppeared = YES;

    if(self.event) {
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    [_appDelegate.geofenceManager performAfterRetrievingCurrentLocationWithCompletion:^(CLLocation * _Nullable currentLocation) {
        _location = currentLocation;
        
        [self setupLocation:currentLocation];
        
        [self reverseGeocodeForNearestPlacemark:^(CLPlacemark *placemark) {
            [_locationButton setTitle:[self addressFromPlacemark:placemark] forState:UIControlStateNormal];
            _gotCurrentLocation = YES;
        }];
        
        [SVProgressHUD dismiss];
    }];
}

- (void)setupLocation:(CLLocation *)currentLocation
{
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView removeOverlay:_radialCircle];

    if (self.event) {
        [_mapView zoomToLocation:currentLocation withMarginInMeters:self.event.radius.floatValue animated:YES];
    } else {
        [_mapView setCenterCoordinate:currentLocation.coordinate zoomLevel:15 animated:YES];
    }

    [_mapView addAnnotation:
     [[GeofenceAnnotation alloc] initWithCoordinate:currentLocation.coordinate]
     ];
    
    _radialCircle = [MKCircle circleWithCenterCoordinate:currentLocation.coordinate radius:self.event?[self.event.radius doubleValue]:_radiusSlider.value];
    [_mapView addOverlay:_radialCircle];
    [self changeRadius:_radiusSlider];
}

#pragma mark - TableView Delegate
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (self.event) {
            return 0.0f;
        }
    }
    if(indexPath.section == 1 || indexPath.section == 2) {
        if(_geofenceType == GeofenceTypeGeofence) {
            return 0.0f;
        }
    } else if (indexPath.section == 3 || indexPath.section == 4 || indexPath.section == 5) {
        if (_geofenceType == GeofenceTypeIBeacon) {
            return 0.0f;
        }
    } else if (indexPath.section == 8) {
        if (_geofenceType == GeofenceTypeIBeacon) {
            return 0.0f;
        }
        if ([_appDelegate.settings apiToken].length == 0) {
            return 0.0f;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 1 || section == 2) {
        if(_geofenceType == GeofenceTypeGeofence) {
            return 0.0f;
        }
    } else if (section == 3 || section == 4 || section == 5) {
        if (_geofenceType == GeofenceTypeIBeacon) {
            return 0.0f;
        }
    }
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

#pragma mark - MapView Delegate

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation
{
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier: @"pin"];
    if (pin == nil)
    {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"pin"];
    }
    else
    {
        pin.annotation = annotation;
    }
    pin.animatesDrop = YES;
    pin.draggable = YES;
    
    return pin;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if(newState == MKAnnotationViewDragStateStarting)
    {
        [_mapView removeOverlay:_radialCircle];
        [_geocoder cancelGeocode];
        _gotCurrentLocation = NO;
    }
    else if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        _location = [[CLLocation alloc] initWithLatitude:droppedAt.latitude longitude:droppedAt.longitude];
        _radialCircle = [MKCircle circleWithCenterCoordinate:_location.coordinate radius:self.event?[self.event.radius doubleValue]:_radiusSlider.value];
        [_mapView addOverlay:_radialCircle];
        [self changeRadius:_radiusSlider];
        
        NSLog(@"Pin dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
        
        [self reverseGeocodeForNearestPlacemark:^(CLPlacemark *placemark) {
            [_locationButton setTitle:[self addressFromPlacemark:placemark] forState:UIControlStateNormal];
            _gotCurrentLocation = YES;
        }];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKCircleRenderer * renderer = [[MKCircleRenderer alloc] initWithCircle:_radialCircle];
    renderer.strokeColor = [UIColor blackColor];
    renderer.fillColor = [UIColor redColor];
    renderer.alpha = .5f;
    return renderer;
}

- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    _radiusSlider.maximumValue = (250.0f * [mapView radiusMultiplier]);
    
    if (self.event && !_viewAppeared) {
        _radiusSlider.maximumValue = self.event.radius.floatValue;
        _radiusSlider.value = _radiusSlider.maximumValue;
    }
}

#pragma mark - TextField Delegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBActions
- (IBAction) toggleType:(UISegmentedControl *)sgControl
{
    if(sgControl.selectedSegmentIndex == 1) {
        _geofenceType = GeofenceTypeIBeacon;
    } else {
        _geofenceType = GeofenceTypeGeofence;
    }

    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:(NSRange){1,4}] withRowAnimation:UITableViewRowAnimationNone];
    
    [UIView animateWithDuration:.25f animations:^{
        _iBeaconPicker.alpha = (_geofenceType == GeofenceTypeIBeacon) ? 1.0f : 0.0f;
    } completion:^(BOOL finished) {
        _iBeaconPicker.hidden = !(_geofenceType == GeofenceTypeIBeacon);
    }];
}

- (IBAction)locationButtonTapped:(id)sender {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Address", @"Enter Geofences Address dialog title")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:nil];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Use", @"Use Address Button title") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *address = [alertController.textFields[0] text];
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [_geocoder cancelGeocode];
        [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placemark = [placemarks firstObject];
            if (placemark) {
                _location = placemark.location;
                [self setupLocation:placemark.location];
                [_locationButton setTitle:[self addressFromPlacemark:placemark] forState:UIControlStateNormal];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                               message:NSLocalizedString(@"No location found. Please refine your query.", @"No location according to the entered address was found")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
                [strongSelf presentViewController:alert animated:YES completion:nil];
            }
            [SVProgressHUD dismiss];
        }];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)deleteClicked:(id)sender
{
    if (!self.event) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"Really delete this Entry?", @"Confirmation when deleting Gefoence/iBeacon")
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.event delete];
        if (self.event.managedObjectContext) {
            [self.event save];
        }
        [_appDelegate.geofenceManager syncMonitoredRegions];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)backupClicked:(id)sender
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"This Geofence will be sent to your my.locative.io Account, you may then use it on any other Device. Would you like to do this?", @"Confirmation when uploading Geofence to my.locative.io")
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Backup", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [_appDelegate.cloudManager uploadGeofence:self.event onFinish:^(NSError *error) {
            [SVProgressHUD dismiss];
            if (error) {
                return [self showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                        message:NSLocalizedString(@"An error occured when backing up your Geofence, please try again.", nil)];
            }
            [self showAlertWithTitle:NSLocalizedString(@"Note", nil)
                             message:NSLocalizedString(@"Your Geofence has been backed up successfully.", nil)];
        }];
    }]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                          message:message
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Geofence Actions
- (IBAction)changeRadius:(UISlider *)slider
{
    if (!_viewAppeared) {
        return;
    }
    
    NSOperationQueue *currentQueue = [NSOperationQueue new];
    __block MKCircle *radialCircle = nil;
    
    NSOperation *createOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            radialCircle = [MKCircle circleWithCenterCoordinate:_location.coordinate radius:slider.value];
            [_mapView addOverlay:radialCircle];
        });
    }];
    
    NSOperation *removeOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView removeOverlay:_radialCircle];
            @synchronized(self){
                _radialCircle = radialCircle;
            }
        });
    }];
    
    [removeOperation addDependency:createOperation];
    [currentQueue addOperations:@[createOperation, removeOperation] waitUntilFinished:YES];
}

- (void)reverseGeocodeForNearestPlacemark:(void(^)(CLPlacemark *placemark))cb
{
    [_geocoder cancelGeocode];
    [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
        cb([placemarks firstObject]);
    }];
}

- (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
{
    if (!placemark) {
        return NSLocalizedString(@"Unknown Location", @"Unknown Location");
    }
    NSString *eventName = @"";
    for (int i = 0; i < [[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] count]; i++) {
        NSString *part = [[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:i];
        eventName = [eventName stringByAppendingFormat:@"%@", part];
        
        if(i < ([[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] count] - 1)) {
            eventName = [eventName stringByAppendingString:@", "];
        }
    }
    return eventName;
}

- (IBAction)saveEvent:(id)sender
{
    // iBeacon: Check if exceeding uint16
    if (_geofenceType == GeofenceTypeIBeacon) {
        if (![[NSUUID alloc] initWithUUIDString:_iBeaconUuidTextField.text]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:[NSString stringWithFormat:NSLocalizedString(@"Invalid UUID, iBeacon UUIDs need to be in valid UUID format to work as expected.", nil), UINT16_MAX]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            return [self presentViewController:alert animated:YES completion:nil];
        }
        if ([[self.majorMinorFormatter numberFromString:_iBeaconMajorTextField.text] intValue] > UINT16_MAX ||
            [[self.majorMinorFormatter numberFromString:_iBeaconMinorTextField.text] intValue] > UINT16_MAX) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:[NSString stringWithFormat:NSLocalizedString(@"Minor / Major value must not exceed: %d. Please change your Values.", nil), UINT16_MAX]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            return [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    if (_geofenceType == GeofenceTypeGeofence) {
        NSString *uuid = (self.event)?self.event.uuid:[[NSUUID UUID] UUIDString];
        if (!_gotCurrentLocation) {
            [self reverseGeocodeForNearestPlacemark:^(CLPlacemark *placemark) {
                NSString *eventName = [NSString stringWithFormat:@"Event (%@)", uuid];
                if (placemark) {
                    eventName = [self addressFromPlacemark:placemark];
                    NSLog(@"Event Name: %@", eventName);
                }
                [self saveEventWithEventName:eventName andUuid:uuid];
                _gotCurrentLocation = YES;
            }];
        } else {
            [self saveEventWithEventName:_locationButton.titleLabel.text andUuid:uuid];
        }
    } else {
        NSString *eventName = [NSString stringWithFormat:@"iBeacon (%@)", _iBeaconUuidTextField.text];
        [self saveEventWithEventName:eventName andUuid:_iBeaconUuidTextField.text];
    }
}

- (NSNumberFormatter *)majorMinorFormatter
{
    if (!_majorMinorFormatter) {
        _majorMinorFormatter = [[NSNumberFormatter alloc] init];
        [_majorMinorFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }
    return _majorMinorFormatter;
}

- (void) saveEventWithEventName:(NSString *)eventName andUuid:(NSString *)uuid
{
    NSNumber *triggers = [NSNumber numberWithInt:(TriggerEnter | TriggerExit)];
    if(!_enterSwitch.on && _exitSwitch.on)
    {
        triggers = [NSNumber numberWithInt:(TriggerExit)];
    }
    else if(_enterSwitch.on && !_exitSwitch.on)
    {
        triggers = [NSNumber numberWithInt:(TriggerEnter)];
    }
    else if(!_enterSwitch.on && !_exitSwitch.on)
    {
        triggers = [NSNumber numberWithInt:0];
    }
    
    if(!self.event)
    {
        self.event = [Geofence create];
        self.event.uuid = uuid;
    }
    
    self.event.name = eventName;
    self.event.triggers = triggers;
    self.event.type = [NSNumber numberWithInt:_geofenceType];
    
    // Geofence
    if (_geofenceType == GeofenceTypeGeofence) {
        self.event.latitude = [NSNumber numberWithDouble:[_location coordinate].latitude];
        self.event.longitude = [NSNumber numberWithDouble:[_location coordinate].longitude];
        self.event.radius = [NSNumber numberWithDouble:_radiusSlider.value];
        self.event.customId = [_customLocationId text];
    }
    
    // iBeacon
    if (_geofenceType == GeofenceTypeIBeacon) {
        self.event.iBeaconUuid = _iBeaconUuidTextField.text;
        self.event.iBeaconMajor = [self.majorMinorFormatter numberFromString:_iBeaconMajorTextField.text];//@([_iBeaconMajorTextField.text longLongValue]);
        self.event.iBeaconMinor = [self.majorMinorFormatter numberFromString:_iBeaconMinorTextField.text];//@([_iBeaconMinorTextField.text longLongValue]);
        self.event.customId = [_iBeaconCustomId text];
        
    }
    
    // Normalize URLs (if necessary)
    if([[_enterUrlTextField text] length] > 0) {
        if([[[_enterUrlTextField text] lowercaseString] hasPrefix:@"http://"] || [[[_enterUrlTextField text] lowercaseString] hasPrefix:@"https://"]) {
            self.event.enterUrl = _enterUrlTextField.text;
        } else {
            self.event.enterUrl = [@"http://" stringByAppendingString:_enterUrlTextField.text];
        }
    } else {
        self.event.enterUrl = nil;
    }
    
    if([[_exitUrlTextField text] length] > 0) {
        if([[[_exitUrlTextField text] lowercaseString] hasPrefix:@"http://"] || [[[_exitUrlTextField text] lowercaseString] hasPrefix:@"https://"]) {
            self.event.exitUrl = _exitUrlTextField.text;
        } else if ([[_exitUrlTextField text] length] > 0) {
            self.event.exitUrl = [@"http://" stringByAppendingString:_exitUrlTextField.text];
        }
    } else {
        self.event.exitUrl = nil;
    }
    
    self.event.enterMethod = [NSNumber numberWithInt:([_enterMethod.titleLabel.text isEqualToString:@"POST"])?0:1];
    self.event.exitMethod = [NSNumber numberWithInt:([_exitMethod.titleLabel.text isEqualToString:@"POST"])?0:1];
    
    self.event.httpAuth = [NSNumber numberWithBool:_httpAuthSwitch.on];
    self.event.httpUser = _httpUsernameTextField.text;
    self.event.httpPasswordSecure = _httpPasswordTextField.text;
    [self.event save];
    
    [_appDelegate.geofenceManager syncMonitoredRegions];
    
    [SVProgressHUD dismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)toggleHttpBasicAuth:(id)sender
{
    [_httpUsernameTextField setEnabled:_httpAuthSwitch.on];
    [_httpPasswordTextField setEnabled:_httpAuthSwitch.on];
}

#pragma mark - Method Buttons
- (IBAction)selectEnterMethod:(id)sender {
    [self selectMethodForButton:_enterMethod sender:sender];
}

- (IBAction)selectExitMethod:(id)sender {
    [self selectMethodForButton:_exitMethod sender:sender];
}

- (void)selectMethodForButton:(UIButton *)button sender:(id)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select http-method", nil)
                                                                          message:NSLocalizedString(@"Please chose the method which shall be used", nil)
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"GET", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [button setTitle:@"GET" forState:UIControlStateNormal];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"POST", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [button setTitle:@"POST" forState:UIControlStateNormal];
    }]];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _iBeaconPresets.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _iBeaconPresets[row][@"name"];
}

#pragma mark - UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSDictionary *iBeaconPreset = _iBeaconPresets[row];
    _iBeaconUuidTextField.text = iBeaconPreset[@"uuid"];
    _iBeaconMajorTextField.text = iBeaconPreset[@"major"];
    _iBeaconMinorTextField.text = iBeaconPreset[@"minor"];
}

@end
