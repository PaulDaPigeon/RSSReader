//
//  AppDelegate.m
//  nocoredata
//
//  Created by Hebok Pal on 6/2/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MagicalRecord.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setupCoreDataStack];
    
    return YES;
}

@end
