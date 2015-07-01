//
//  FeedParserTest.m
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
#import "FeedParser.h"
#import "Article.h"

@interface FeedParserTest : XCTestCase

@end

const char *contentsOfXML = "<?xml version=\"1.0\" encoding=\"windows-1252\"?>\n<rss version=\"2.0\">\n<channel>\n<title>Sample Title</title>\n<image>\n<url>http://www.feedforall.com/ffalogo48x48.gif</url>\n</image>\n<item>\n<title>Article 1</title>\n<description>\nDescription of article 1.\n</description>\n<link>http://www.testfeed.com/article1</link>\n<pubDate>Mon, 11 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 2</title>\n<description>\nDescription of article 2.\n</description>\n<link>http://www.testfeed.com/article2</link>\n<pubDate>Tue, 12 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 3</title>\n<description>\nDescription of article 3.\n</description>\n<link>http://www.testfeed.com/article3</link>\n<pubDate>Wed, 13 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 4</title>\n<description>\nDescription of article 4.\n</description>\n<link>http://www.testfeed.com/article4</link>\n<pubDate>Thu, 14 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 5</title>\n<description>\nDescription of article 5.\n</description>\n<link>http://www.testfeed.com/article5</link>\n<pubDate>Fri, 15 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 6</title>\n<description>\nDescription of article 6.\n</description>\n<link>http://www.testfeed.com/article6</link>\n<pubDate>Sat, 16 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 7</title>\n<description>\nDescription of article 7.\n</description>\n<link>http://www.testfeed.com/article7</link>\n<pubDate>Sun, 17 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 8</title>\n<description>\nDescription of article 8.\n</description>\n<link>http://www.testfeed.com/article8</link>\n<pubDate>Mon, 18 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 9</title>\n<description>\nDescription of article 9.\n</description>\n<link>http://www.testfeed.com/article9</link>\n<pubDate>Tue, 19 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n</channel>\n</rss>";

NSString * const DATE_FORMAT = @"MMM yyyy HH:mm:ss z";

SPEC_BEGIN(FeedParserSpec)

describe(@"FeedParser", ^{
    
    __block Feed *feed;
    __block FeedParser *feedParser;
    __block NSString *feedURL;
    __block NSError *error;
    
    beforeAll(^{
        NSString *contentsOfXMLString = [NSString stringWithFormat:@"%s", contentsOfXML];
        NSData *data = [[NSData alloc] initWithBytes:contentsOfXML length:contentsOfXMLString.length];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"TestFeed.xml"];
        [data writeToFile:appFile atomically:NO];
        feedURL = [[NSString stringWithFormat:@"%@", @"file:///"] stringByAppendingString:appFile];
    });
    
    beforeEach(^{
        feed = [Feed MR_createEntity];
        feedParser = [[FeedParser alloc] init];
        error = nil;
        
        [feed setFeedURL:feedURL];
        [feed setName:@"Original name"];
        [feedParser parseFeed:feed andShouldAutoDetectName:NO error:&error];
    });
    
    afterEach(^{
        [feed MR_deleteEntity];
    });
    
    it(@"should add articles to feed", ^{
        [[feed.articles should] haveCountOfAtLeast:1];
    });
    
    it(@"should add 9 articles to feed", ^{
        [[feed.articles should] haveCountOf:9];
    });
    
    it(@"should not change Feed name", ^{
        [[feed should] haveValue:@"Original name" forKey:@"name"];
    });
    
    it(@"should change Feed name to FeedForAll Sample Feed", ^{
        [feedParser parseFeed:feed andShouldAutoDetectName:YES error:&error];
        
        [[feed should] haveValue:@"Sample Title" forKey:@"name"];
    });
    
    it(@"should have imageURL", ^{
        [[feed should] haveValue:@"http://www.feedforall.com/ffalogo48x48.gif" forKey:@"image"];
    });
    
    it(@"should have publication date for all articles", ^{
       for (Article *article in [feed.articles allObjects])
       {
           [[article.publicationDate shouldNot] beNil];
       }
    });
    
    it(@"should have the expected articles", ^{
        NSArray *articleArray = [feed.articles allObjects];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"publicationDate" ascending:YES];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:DATE_FORMAT];
        
        articleArray = [articleArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        for (NSInteger incrementer = 0; incrementer < articleArray.count; incrementer++)
        {
            Article *article = [articleArray objectAtIndex:incrementer];
            
            [[article should] haveValue:[NSString stringWithFormat:@"Article %li", (incrementer + 1)] forKey:@"title"];
            [[article should] haveValue:[NSString stringWithFormat:@"Description of article %li.", (incrementer + 1)] forKey:@"articleDescription"];
            [[article should] haveValue:[NSString stringWithFormat:@"http://www.testfeed.com/article%li", (incrementer + 1)] forKey:@"link"];
            [[article should] haveValue:[formatter dateFromString:[NSString stringWithFormat:@"1%li Oct 2004 11:00:00 -0400", (incrementer +1)]] forKey:@"publicationDate"];
        }
    });
    
    it(@"should fail with invalid URL", ^{
        [feed setFeedURL:@"asdf"];
        [feedParser parseFeed:feed andShouldAutoDetectName:NO error:&error];
        
        [[error shouldNot] beNil];
        [[error should] haveValue:@"com.bitfall" forKey:@"domain"];
        [[error.userInfo should] haveValue:@"Could not load xml from url" forKey:NSLocalizedDescriptionKey];
        [[theValue(error.code) should] equal:theValue(NSURLErrorBadURL)];
    });
     
});

SPEC_END