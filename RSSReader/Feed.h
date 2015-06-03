//
//  Feed.h
//  
//
//  Created by Hebok Pal on 6/3/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * feedURL;
@property (nonatomic, retain) NSString * name;

@end
