#import "GeofencesViewController.h"
#import "AddEditGeofenceViewController.h"
#import "Config.h"
#import "AppDelegate.h"

@import PSTAlertController;
@import ObjectiveSugar;
@import ObjectiveRecord;

@interface GeofencesViewController ()

@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, strong) Geofence *selectedEvent;
@property (nonatomic, strong) Config *config;
@property (nonatomic, assign) BOOL viewDidAppear;

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
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[self.appDelegate geofenceManager] cleanup];
    
    self.config = [[Config alloc] init];

    /*
     Drawer Menu Shadow
     */
    self.parentViewController.view.layer.shadowOpacity = 0.75f;
    self.parentViewController.view.layer.shadowRadius = 10.0f;
    self.parentViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadGeofences) name:kReloadGeofences object:nil];
    
    if(!self.viewDidAppear && [[Geofence all] count] == 0) {
        [self performSegueWithIdentifier:@"AddEvent" sender:self];
    }
    
    if(self.viewDidAppear) {
        [self.tableView reloadData];
    }
    
    if (![self.config backgroundFetchMessageShown]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Note", nil)
                                    message:NSLocalizedString(@"Please make sure to enable \"Background App Fetch\" inside your Device's Settings. This is required for the App to work flawlessly.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil, nil] show];
        [self.config setBackgroundFetchMessageShown:YES];
    }

    self.viewDidAppear = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadGeofences object:nil];
}

- (void) reloadGeofences
{
    [self.tableView reloadData];
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
    } else if ([event.type intValue] == GeofenceTypeIbeacon) {
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
        [[self.appDelegate geofenceManager] stopMonitoringEvent:event];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
    if ([Geofence maximumReachedShowingAlert:YES viewController:self]) {
        return;
    }
    
    if ([self.appDelegate.settings apiToken].length > 0) {
        // User is logged in, ask wether to import Geofence
        PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Would you like to add a new Geofence locally or import it from my.locative.io?", nil)
                                                                              message:nil
                                                                       preferredStyle:PSTAlertControllerStyleActionSheet];
        [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:PSTAlertActionStyleCancel handler:nil]];
        [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Add locally", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
            [self performSegueWithIdentifier:@"AddEvent" sender:self];
        }]];
        [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Import", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
            [self performSegueWithIdentifier:@"Import" sender:self];
        }]];
        [controller showWithSender:self.view controller:self animated:YES completion:nil];
        return;
    }
    
    [self performSegueWithIdentifier:@"AddEvent" sender:self];
    
}

- (IBAction) toggleMenu:(id)sender
{
    [[(AppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateOpen animated:YES allowUserInterruption:YES completion:nil];
}

@end
