//
//  Article.h
//  RSSReader
//
//  Created by Hebok Pal on 6/9/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feed;

@interface Article : NSManagedObject

@property (nonatomic, retain) NSString * articleDescription;
@property (nonatomic, retain) NSNumber * isUnread;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSDate * publicationDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Feed *feed;

@end
