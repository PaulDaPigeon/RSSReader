//
//  FeedParser.h
//  RSSReader
//
//  Created by Hebok Pal on 6/24/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feed.h"

@interface FeedParser : NSObject <NSXMLParserDelegate>

/**
 Parses an RSS feed for articles.
 The changes made are effective on the feed received as the paramater. The address of the feed is taken from the link property of the feed. The articles stored in the article are preserved, newly published ones are added aside them.
 @param feed The feed containing which will be parsed. Newly found articles are also added to this feed.
 @param shouldAutoDetectname If yes is passed it will overwrite any custom names given to the feed with the one published.
 */
-(void)parseFeed:(Feed *)feed andShouldAutoDetectName:(Boolean)shouldAutoDetectName error:(NSError **)error;
@end
