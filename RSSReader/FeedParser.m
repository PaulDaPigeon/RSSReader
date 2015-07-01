//
//  FeedParser.m
//  RSSReader
//
//  Created by Hebok Pal on 6/24/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import "FeedParser.h"
#import "MagicalRecord.h"
#import "Article.h"


NSString *currentElement;
NSMutableString *currentTitle;
NSMutableString *currentImage;
NSMutableString *currentPublicationDate;
NSMutableString *currentLink;
NSMutableString *currentArticleDescription;
NSString *feedName;
Feed *currentFeed;
Article *currentArticle;
Boolean shouldAutodetectName;
Boolean inImageElement;
Boolean inItemElement;


NSString * const ITEM_ELEMENT = @"item";
NSString * const LINK_ELEMENT = @"link";
NSString * const TITLE_ELEMENT = @"title";
NSString * const DESCRIPTION_ELEMENT = @"description";
NSString * const PUBLICATION_DATE_ELEMENT = @"pubDate";
NSString * const IMAGE_ELEMENT = @"image";
NSString * const URL_ELEMENT = @"url";
NSString * const RFC822_DATE_FORMAT = @"EEE, dd MMM yyyy HH:mm:ss z";

@implementation FeedParser

-(void)parseFeed:(Feed *)feed andShouldAutoDetectName:(Boolean)shouldAutoDetectName error:(NSError **) error
{
    shouldAutodetectName = shouldAutoDetectName;
    NSURL *url = [NSURL URLWithString:feed.feedURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    if (![NSURLConnection canHandleRequest:request])
    {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Could not load xml from url" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"com.bitfall" code:NSURLErrorBadURL userInfo:errorDetail];
        return;
    }
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:NO];
    currentFeed = feed;
    [parser parse];
    if (shouldAutoDetectName)
    {
        feed.name = feedName;
    }
}

#pragma mark - ParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    currentElement = elementName;
    
    if ([currentElement isEqualToString:ITEM_ELEMENT]) {
        
        currentArticle = [Article MR_createEntity];
        currentArticleDescription = [[NSMutableString alloc] init];
        currentLink = [[NSMutableString alloc] init];
        currentPublicationDate = [[NSMutableString alloc] init];
        currentTitle = [[NSMutableString alloc] init];
        inItemElement = YES;
    }
    
    else if (!inItemElement && shouldAutodetectName)
    {
        currentTitle = [[NSMutableString alloc] init];
    }
    
    if ([currentElement isEqualToString:IMAGE_ELEMENT])
    {
        currentImage = [[NSMutableString alloc] init];
        inImageElement = YES;
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([currentElement isEqualToString:TITLE_ELEMENT] && !inImageElement) {
        [currentTitle appendString:string];
    }
    else if ([currentElement isEqualToString:LINK_ELEMENT]) {
        [currentLink appendString:string];
    }
    else if ([currentElement isEqualToString:PUBLICATION_DATE_ELEMENT])
    {
        [currentPublicationDate appendString:string];
    }
    else if ([currentElement isEqualToString:DESCRIPTION_ELEMENT])
    {
        [currentArticleDescription appendString:string];
    }
    else if (inImageElement)
        if ([currentElement isEqualToString:URL_ELEMENT])
        {
            [currentImage appendString:string];
        }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
    if ([elementName isEqualToString:ITEM_ELEMENT]) {
        currentTitle = [[self removeTrailingWhitespaceFromString:currentTitle] mutableCopy];
        currentArticleDescription = [[self removeTrailingWhitespaceFromString:currentArticleDescription] mutableCopy];
        currentLink = [[self removeTrailingWhitespaceFromString:currentLink] mutableCopy];
        currentPublicationDate = [[self removeTrailingWhitespaceFromString:currentPublicationDate] mutableCopy];
        
        currentArticle.title = currentTitle;
        currentArticle.articleDescription = currentArticleDescription;
        currentArticle.link = currentLink;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:RFC822_DATE_FORMAT];
        currentArticle.publicationDate = [formatter dateFromString:currentPublicationDate];
        
        NSArray *oldArticles = [currentFeed.articles allObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.link contains %@",currentArticle.link];
        NSArray *resultArray = [oldArticles filteredArrayUsingPredicate:predicate];
        
        if (resultArray.count != 0)
        {
            [currentArticle MR_deleteEntity];
        }
        else{
            currentArticle.isUnread = [NSNumber numberWithInt:1];
            [currentFeed addArticlesObject:currentArticle];
            currentFeed.unreadArticleCount = [NSNumber numberWithLong:[currentFeed.unreadArticleCount integerValue] + 1l];
        }
        inItemElement = NO;
    }
    
    if (!inItemElement && !inImageElement && shouldAutodetectName && [elementName isEqualToString:TITLE_ELEMENT])
    {
        currentTitle = [[self removeTrailingWhitespaceFromString:currentTitle] mutableCopy];
        currentTitle = [[currentTitle stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        feedName = [currentTitle copy];
    }
    
    if ([elementName isEqualToString:IMAGE_ELEMENT])
    {
        currentImage = [[self removeTrailingWhitespaceFromString:currentImage] mutableCopy];
        currentImage = [[currentImage stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        currentFeed.image = currentImage;
        inImageElement = NO;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
}

#pragma mark - StringHelper

-(NSString *)removeTrailingWhitespaceFromString:(NSString *)string
{
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+$" options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (!error)
    {
        string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    }
    
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return string;
}

@end
