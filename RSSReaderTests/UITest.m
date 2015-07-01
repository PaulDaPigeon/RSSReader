//
//  UITest.m
//  RSSReader
//
//  Created by Hebok Pal on 6/30/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KIF.h"

@interface UITest : KIFTestCase

@end

const char *contentsOfXML1 = "<?xml version=\"1.0\" encoding=\"windows-1252\"?>\n<rss version=\"2.0\">\n<channel>\n<title>Sample Title</title>\n<image>\n<url>http://www.feedforall.com/ffalogo48x48.gif</url>\n</image>\n<item>\n<title>Article 1</title>\n<description>\nDescription of article 1.\n</description>\n<link>http://www.testfeed.com/article1</link>\n<pubDate>Mon, 11 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 2</title>\n<description>\nDescription of article 2.\n</description>\n<link>http://www.testfeed.com/article2</link>\n<pubDate>Tue, 12 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 3</title>\n<description>\nDescription of article 3.\n</description>\n<link>http://www.testfeed.com/article3</link>\n<pubDate>Wed, 13 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 4</title>\n<description>\nDescription of article 4.\n</description>\n<link>http://www.testfeed.com/article4</link>\n<pubDate>Thu, 14 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 5</title>\n<description>\nDescription of article 5.\n</description>\n<link>http://www.testfeed.com/article5</link>\n<pubDate>Fri, 15 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 6</title>\n<description>\nDescription of article 6.\n</description>\n<link>http://www.testfeed.com/article6</link>\n<pubDate>Sat, 16 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 7</title>\n<description>\nDescription of article 7.\n</description>\n<link>http://www.testfeed.com/article7</link>\n<pubDate>Sun, 17 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 8</title>\n<description>\nDescription of article 8.\n</description>\n<link>http://www.testfeed.com/article8</link>\n<pubDate>Mon, 18 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n<item>\n<title>Article 9</title>\n<description>\nDescription of article 9.\n</description>\n<link>http://www.testfeed.com/article9</link>\n<pubDate>Tue, 19 Oct 2004 11:00:00 -0400</pubDate>\n</item>\n</channel>\n</rss>";

const char *contentsOfXML2 = "<?xml version=\"1.0\" encoding=\"windows-1252\"?>\n<rss version=\"2.0\">\n<channel>\n<title>Sample Title</title>\n<image>\n<url>http://www.feedforall.com/ffalogo48x48.gif</url>\n</image>\n<item>\n<title>Feed 2 article 1</title>\n<description>\nDescription of feed 2 article 1.\n</description>\n<link>http://www.testfeed.com/article1</link>\n<pubDate>Mon, 11 Oct 2003 11:00:00 -0400</pubDate>\n</item>\n</channel>\n</rss>";

NSString *feedURL1;
NSString *feedURL2;

@implementation UITest

- (void)beforeAll
{
    NSString *contentsOfXMLString = [NSString stringWithFormat:@"%s", contentsOfXML1];
    NSData *data = [[NSData alloc] initWithBytes:contentsOfXML1 length:contentsOfXMLString.length];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"TestFeed.xml"];
    [data writeToFile:appFile atomically:NO];
    feedURL1 = [[NSString stringWithFormat:@"%@", @"file:///"] stringByAppendingString:appFile];
    
    contentsOfXMLString = [NSString stringWithFormat:@"%s", contentsOfXML2];
    data = [[NSData alloc] initWithBytes:contentsOfXML2 length:contentsOfXMLString.length];
    appFile = [documentsDirectory stringByAppendingPathComponent:@"TestFeed2.xml"];
    [data writeToFile:appFile atomically:NO];
    feedURL2 = [[NSString stringWithFormat:@"%@", @"file:///"] stringByAppendingString:appFile];
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Add new feed"];
    [tester enterText:@"Test feed" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester enterText:feedURL1 intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Test feed"];
}

- (void)testMarkingAFeedAsReadFromFeedsOfAnArticle
{
    [tester waitForViewWithAccessibilityLabel:@"9"];
    [tester tapViewWithAccessibilityLabel:@"Test feed, 9"];
    [tester waitForViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Feeds"];
    [tester waitForViewWithAccessibilityLabel:@"8"];
}

- (void)testAddingandDeletingAFeedWithNameAutoDetection
{
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Add new feed"];
    [tester enterText:feedURL1 intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Sample Title"];
    [tester swipeViewWithAccessibilityLabel:@"Sample Title" inDirection:KIFSwipeDirectionLeft];
    [tester waitForViewWithAccessibilityLabel:@"Delete"];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
}

- (void)testMarkingAFeedAsReadFromAllArticles
{
    [tester waitForViewWithAccessibilityLabel:@"9"];
    [tester tapViewWithAccessibilityLabel:@"Articles"];
    [tester waitForViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Article 1, Description of article 1."];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Feeds"];
    [tester waitForViewWithAccessibilityLabel:@"8"];
}

- (void)testCanNavigateToAllArticlesFromArticlesOfAFeed
{
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Add new feed"];
    [tester enterText:@"Test feed 2" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester enterText:feedURL2 intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester waitForViewWithAccessibilityLabel:@"Test feed 2"];
    
    [tester tapViewWithAccessibilityLabel:@"Test feed, 9"];
    [tester waitForViewWithAccessibilityLabel:@"Article 1"];
    [tester tapViewWithAccessibilityLabel:@"Show all"];
    [tester waitForViewWithAccessibilityLabel:@"Feed 2 article 1, Description of feed 2 article 1."];
    [tester tapViewWithAccessibilityLabel:@"Feeds"];
    [tester swipeViewWithAccessibilityLabel:@"Test feed 2" inDirection:KIFSwipeDirectionLeft];
    [tester waitForViewWithAccessibilityLabel:@"Delete"];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
}

- (void)testCanEditFeedName
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForViewWithAccessibilityLabel:@"Edit feed"];
    [tester enterText:@"\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester enterText:@"Changed name" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester tapViewWithAccessibilityLabel:@"Save changes"];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForViewWithAccessibilityLabel:@"Edit feed"];
    [tester enterText:@"\b\b\b\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester enterText:@"Test feed" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester tapViewWithAccessibilityLabel:@"Save changes"];
}

- (void)testCanEditFeedURL
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForViewWithAccessibilityLabel:@"Edit feed"];
    
    [tester enterText:@"\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester enterText:feedURL2 intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester tapViewWithAccessibilityLabel:@"Save changes"];
    [tester waitForViewWithAccessibilityLabel:@"Test feed, 1"];
}

- (void)testCanEditFeedNameAndURLAtOnceWithNameAutoDetection
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForViewWithAccessibilityLabel:@"Edit feed"];
    [tester enterText:@"\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"Name textfield"];
    
    [tester enterText:@"\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester enterText:feedURL2 intoViewWithAccessibilityLabel:@"URL textfield"];
    [tester tapViewWithAccessibilityLabel:@"Save changes"];
    [tester waitForViewWithAccessibilityLabel:@"Sample Title, 1"];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForViewWithAccessibilityLabel:@"Edit feed"];
    [tester enterText:@"\b\b\b\b\b\b\b\b\b\b\b\b" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester enterText:@"Test feed" intoViewWithAccessibilityLabel:@"Name textfield"];
    [tester tapViewWithAccessibilityLabel:@"Save changes"];
}

- (void)afterEach
{
    [tester swipeViewWithAccessibilityLabel:@"Test feed" inDirection:KIFSwipeDirectionLeft];
    [tester waitForViewWithAccessibilityLabel:@"Delete"];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
}

@end
