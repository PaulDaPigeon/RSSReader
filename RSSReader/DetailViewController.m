//
//  DetailViewController.m
//  RSSReader
//
//  Created by Hebok Pal on 6/2/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import "DetailViewController.h"
#import "Article.h"

@interface DetailViewController () <UIGestureRecognizerDelegate>

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [leftRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.webView addGestureRecognizer:leftRecognizer];
    [leftRecognizer setDelegate:self];
    
    UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [rightRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.webView addGestureRecognizer:rightRecognizer];
    [rightRecognizer setDelegate:self];
    
    UINavigationController *navigationController  = (UINavigationController*) [self.navigationController.viewControllers objectAtIndex:1];
    navigationController.navigationItem.title = [(Article *) [self.fetchedResultsController objectAtIndexPath:self.indexPath] title];
    
    [self loadPage];
}

- (void)loadPage
{
    NSURL *url = [NSURL URLWithString:[(Article *) [self.fetchedResultsController objectAtIndexPath:self.indexPath] link]];
    NSError *error;
    NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (!error)
    {
        NSRange range = [html rangeOfString:@"<body"];
        float inset = 0;
        
        if(range.location != NSNotFound) {
            
            NSString *style = [NSString stringWithFormat:@"<style>div {max-width: %.0fpx;}</style>\n", self.view.bounds.size.width - inset];
            html = [NSString stringWithFormat:@"%@%@%@", [html substringToIndex:range.location] , style, [html substringFromIndex:range.location]];
        }
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<meta name=\"viewport\".*/>" options:NSRegularExpressionCaseInsensitive error:&error];
        
        
        if (!error)
        {
            html = [regex stringByReplacingMatchesInString:html options:0 range:NSMakeRange(0, [html length]) withTemplate:[NSString stringWithFormat:@"<meta name=\"viewport\" content=\"width=%.0f\" />", self.view.bounds.size.width - inset]];
            [self.webView loadHTMLString:html baseURL:url];
            Article *article = [self.fetchedResultsController objectAtIndexPath:self.indexPath];
            article.isUnread = [NSNumber numberWithInt:0];
            [self saveContext];
        }
    }
    else
    {
        NSLog(@"%@", error);
    }
}

-(IBAction)openInBrowser:(id)sender
{
    NSURL *url = [NSURL URLWithString:[(Article *) [self.fetchedResultsController objectAtIndexPath:self.indexPath] link]];
    [[UIApplication sharedApplication] openURL:url];
}

-(void)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
    
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        if (self.indexPath.row < [sectionInfo numberOfObjects])
        {
            self.indexPath = [NSIndexPath indexPathForRow:self.indexPath.row + 1 inSection:self.indexPath.section];
            [self loadPage];
        }
    }
    if (sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        if (self.indexPath.row != 0)
        {
            self.indexPath = [NSIndexPath indexPathForRow:self.indexPath.row - 1 inSection:self.indexPath.section];
            [self loadPage];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void)saveContext
{
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"Error saving context: %@", error.description);
        }
    }];
}

@end
