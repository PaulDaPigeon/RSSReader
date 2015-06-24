//
//  Feed+Counter.m
//  
//
//  Created by Hebok Pal on 6/24/15.
//
//

#import "Feed+Counter.h"
#import "Article.h"

@implementation Feed(Counter)

-(void)countUnreadArticles
{
    self.unreadArticleCount = [NSNumber numberWithInt:0];
    
    NSArray *articleArray =[self.articles allObjects];
    
    for (Article *article in articleArray)
    {
        if ([article.isUnread isEqualToNumber: [NSNumber numberWithInt:1]])
        {
            self.unreadArticleCount = [NSNumber numberWithLong:[self.unreadArticleCount integerValue] + 1];
        }
    }
}

@end
