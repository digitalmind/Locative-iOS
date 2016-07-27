#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <Specta/Specta.h>

#import "MenuViewController.h"

SpecBegin(MenuViewControllerTestsSpec)

__block MenuViewController *sut = nil;

beforeEach(^{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[MenuViewController class]]];
    sut = [storyboard instantiateViewControllerWithIdentifier:@"Menu"];
});

afterEach(^{
    sut = nil;
});

describe(@"the viewcontroller for the menu", ^{
    it(@"should be instance of correct class", ^{
        EXP_expect(sut).to.beInstanceOf(MenuViewController.class);
    });
    
    it(@"should have a data source", ^{
        EXP_expect(sut.tableView.dataSource).toNot.beNil;
    });
    
    it(@"should have a delegate", ^{
        EXP_expect(sut.tableView.delegate).toNot.beNil;
    });
});

SpecEnd
