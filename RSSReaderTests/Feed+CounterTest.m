//
//  Feed+CounterTest.m
//  RSSReader
//
//  Created by Hebok Pal on 6/29/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Kiwi.h"
#import "MagicalRecord.h"
#import "Article.h"
#import "Feed.h"
#import "Feed+Counter.h"
#import "FeedParser.h"

SPEC_BEGIN(Feed_CounterTest)

describe(@"Feed+Counter", ^{
    
    __block Feed *feed;
    __block FeedParser *feedParser;
    __block NSError *error;
    
    beforeEach(^{
        feed = [Feed MR_createEntity];
        feedParser = [[FeedParser alloc] init];
        error = nil;
        
        [feed setFeedURL:@"http://www.feedforall.com/sample.xml"];
        [feedParser parseFeed:feed andShouldAutoDetectName:YES error:&error];
    });
    
    afterEach(^{
        [feed MR_deleteEntity];
    });
    
    it(@"should have 9 unread articles", ^{
        [[feed should] haveValue:[NSNumber numberWithInt:9] forKey:@"unreadArticleCount"];
    });
    
    it(@"should have 8 unread articles after marking one as read", ^{
        [(Article *) [feed.articles.allObjects objectAtIndex:0] setIsUnread:[NSNumber numberWithBool:NO]];
        [feed countUnreadArticles];
        
        [[feed should] haveValue:[NSNumber numberWithInt:8] forKey:@"unreadArticleCount"];
    });
});

SPEC_END
