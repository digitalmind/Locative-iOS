#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <Specta/Specta.h>

#import "AddEditGeofenceViewController.h"

SpecBegin(AddEditGeofenceViewControllerTestsSpec)

__block AddEditGeofenceViewController *sut = nil;

beforeEach(^{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[AddEditGeofenceViewController class]]];
    sut = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([AddEditGeofenceViewController class])];
});

afterEach(^{
    sut = nil;
});

describe(@"the viewcontroller for adding / editing geofences", ^{
    it(@"should be instance of correct class", ^{
        EXP_expect(sut).to.beInstanceOf(AddEditGeofenceViewController.class);
    });
    
    it(@"should have a data source", ^{
        EXP_expect(sut.tableView.dataSource).toNot.beNil;
    });
    
    it(@"should have a delegate", ^{
        EXP_expect(sut.tableView.delegate).toNot.beNil;
    });
});

SpecEnd
