//
//  Feed.h
//  
//
//  Created by Hebok Pal on 6/24/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article;

@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * feedURL;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * unreadArticleCount;
@property (nonatomic, retain) NSSet *articles;
@end

@interface Feed (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

@end
