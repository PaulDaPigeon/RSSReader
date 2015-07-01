//
//  FeedTest.m
//  RSSReader
//
//  Created by Hebok Pal on 6/29/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Kiwi.h"
#import "MagicalRecord.h"
#import "Feed.h"

@interface FeedTest : XCTestCase

@end

SPEC_BEGIN(FeedSpec)

__block Feed *feed;

beforeEach(^{
    feed = [Feed MR_createEntity];
});

afterEach(^{
    [feed MR_deleteEntity];
});

it(@"should exist", ^{
    [[feed shouldNot] beNil];
});

SPEC_END