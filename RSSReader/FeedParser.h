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

-(void)parseFeed:(Feed *)feed andShouldAutoDetectName:(Boolean)shouldAutoDetectName error:(NSError **)error;
@end
