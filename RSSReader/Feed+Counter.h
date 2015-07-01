//
//  Feed+Counter.h
//  
//
//  Created by Hebok Pal on 6/24/15.
//
//

#import "Feed.h"

@interface Feed(Counter)
/**
 Counts how many articles are unread.
 Counts in the articles set of the feed, based on the isUnread property of the Article.
 */
- (void)countUnreadArticles;

@end
