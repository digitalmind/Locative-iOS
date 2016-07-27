#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <Specta/Specta.h>

#import "GeofencesViewController.h"

SpecBegin(GFGeofencesViewControllerTestsSpec)

__block GeofencesViewController *sut = nil;

beforeEach(^{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[GeofencesViewController class]]];
    sut = [storyboard instantiateViewControllerWithIdentifier:@"Geofences"];
});

afterEach(^{
    sut = nil;
});

describe(@"GeofenceViewController", ^{
    
    it(@"should be instance of correct clas", ^{
        EXP_expect(sut).to.beInstanceOf(GFGeofencesViewController.class);
    });
    
    it(@"should have a data source", ^{
        EXP_expect(sut.tableView.dataSource).toNot.beNil;
    });
    
    it(@"should have a delegate", ^{
        EXP_expect(sut.tableView.delegate).toNot.beNil;
    });
});

SpecEnd
