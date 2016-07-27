#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <Specta/Specta.h>

#import "SignupViewController.h"

SpecBegin(GFCloudSignupViewControllerTestsSpec)

__block SignupViewController *sut = nil;

beforeEach(^{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[SignupViewController class]]];
    sut = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([SignupViewController class])];
});

afterEach(^{
    sut = nil;
});

describe(@"the viewcontroller for cloud signup", ^{
    it(@"should be instance of correct class", ^{
        EXP_expect(sut).to.beInstanceOf(GFCloudSignupViewController.class);
    });
    
    it(@"should have a data source", ^{
        EXP_expect(sut.tableView.dataSource).toNot.beNil;
    });
    
    it(@"should have a delegate", ^{
        EXP_expect(sut.tableView.delegate).toNot.beNil;
    });
});

SpecEnd
