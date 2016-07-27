#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <Specta/Specta.h>

#import "SettingsViewController.h"

SpecBegin(SettingsViewControllerTestsSpec)

__block SettingsViewController *sut = nil;

beforeEach(^{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[SettingsViewController class]]];
    sut = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
});

afterEach(^{
    sut = nil;
});

describe(@"the viewcontroller for settings", ^{
    it(@"should be instance of correct class", ^{
        EXP_expect(sut).to.beInstanceOf(SettingsViewController.class);
    });
    
    it(@"should have a data source", ^{
        EXP_expect(sut.tableView.dataSource).toNot.beNil;
    });
    
    it(@"should have a delegate", ^{
        EXP_expect(sut.tableView.delegate).toNot.beNil;
    });
});

SpecEnd
