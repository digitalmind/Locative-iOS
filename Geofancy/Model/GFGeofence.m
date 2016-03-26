//
//  GFEvent.m
//  Geofancy
//
//  Created by Marcus Kida on 13.11.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <PSTAlertController/PSTAlertController.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <ObjectiveRecord/ObjectiveRecord.h>

#import "GFGeofence.h"

@implementation GFGeofence

@dynamic customId;
@dynamic enterMethod;
@dynamic enterUrl;
@dynamic exitMethod;
@dynamic exitUrl;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic radius;
@dynamic triggers;
@dynamic type;
@dynamic uuid;
@dynamic httpAuth;
@dynamic httpPassword;
@dynamic httpUser;

@dynamic iBeaconUuid;
@dynamic iBeaconMajor;
@dynamic iBeaconMinor;

+ (BOOL)maximumReachedShowingAlert:(BOOL)alert viewController:(UIViewController *)vc
{
    if ([[GFGeofence all] count] >= 20) {
        if (alert) {
            PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                  message:NSLocalizedString(@"There's a maximum limit of 20 Geofences per App, please remove some Geofences before adding new ones.", nil)
                                                                           preferredStyle:PSTAlertControllerStyleAlert];
            [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleCancel handler:nil]];
            [controller showWithSender:nil controller:vc animated:YES completion:nil];
        }
        return YES;
    }
    return NO;
}

@end
