//
//  DetailViewController.h
//  RSSReader
//
//  Created by Hebok Pal on 6/2/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSArray *articles;
@property (strong, nonatomic) NSIndexPath *indexPath;

@end

