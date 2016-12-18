#import "Locative-Swift.h"
#import "GeofencesViewController.h"
#import "AddEditGeofenceViewController.h"
#import "Locative-Swift.h"

@import ObjectiveSugar;
@import ObjectiveRecord;

@interface GeofencesViewController ()

@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, strong) Geofence *selectedEvent;
@property (nonatomic, strong) Config *config;
@property (nonatomic, assign) BOOL viewDidAppear;
@property (nonatomic, strong) GeofencesEmptyView *emptyView;

@end

@implementation GeofencesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emptyView = [[[NSBundle mainBundle] loadNibNamed:@"GeofencesEmptyView" owner:self options:nil] objectAtIndex:0];
    self.emptyView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.config = [[Config alloc] init];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateEmptyState {
    if ([Geofence all].count == 0) {
        [self.emptyView removeFromSuperview];
        return [self.view.superview addSubview:self.emptyView];
    }
    [self.emptyView removeFromSuperview];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateEmptyState];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadGeofences) name:kReloadGeofences object:nil];

    if(self.viewDidAppear) {
        [self.tableView reloadData];
    }

    self.viewDidAppear = YES;
    
    UIUserNotificationType types = (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadGeofences object:nil];
}

- (void) reloadGeofences
{
    [self.tableView reloadData];
    [self updateEmptyState];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[Geofence all] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Geofence *event = [[Geofence all] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = event.name;
    
    if ([event.type intValue] == GeofenceTypeGeofence) {
        cell.imageView.image = [UIImage imageNamed:@"icon-geofence"];
    } else if ([event.type intValue] == GeofenceTypeIBeacon) {
        cell.imageView.image = [UIImage imageNamed:@"icon-ibeacon"];
    } else {
        cell.imageView.image = nil;
    }

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"ID: %@", ([[event customId] length] > 0)?event.customId:event.uuid]];
    [string addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize] range:NSMakeRange(0, 3)];
    [cell.detailTextLabel setAttributedText:string];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Geofence *event = [[Geofence all] objectAtIndex:indexPath.row];
        [event delete];
        if (event.managedObjectContext) {
            [event save];
        }
        [[self.appDelegate geofenceManager] syncMonitoredRegions];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self updateEmptyState];
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedEvent = [[Geofence all] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"AddEvent" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"AddEvent"]) {
        AddEditGeofenceViewController *viewController = (AddEditGeofenceViewController *)[segue destinationViewController];
        if(self.selectedEvent) {
            viewController.event = self.selectedEvent;
            self.selectedEvent = nil;
        }
    }
}

#pragma mark - IBActions
- (IBAction) addGeofence:(id)sender
{
    if ([Geofence showMaximumGeofencesReachedWithAlert:YES viewController:self]) {
        return;
    }
    
    if ([self.appDelegate.settings apiToken].length > 0) {
        // User is logged in, ask wether to import Geofence
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Would you like to add a new Geofence locally or import it from my.locative.io?", nil)
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add locally", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"AddEvent" sender:self];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"Import" sender:self];
        }]];
        if (controller.popoverPresentationController) {
            controller.popoverPresentationController.barButtonItem = sender;
        }
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    
    [self performSegueWithIdentifier:@"AddEvent" sender:self];
    
}

@end
