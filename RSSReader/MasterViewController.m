//
//  MasterViewController.m
//  RSSReader
//
//  Created by Hebok Pal on 6/2/15.
//  Copyright (c) 2015 Bitfall. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "MagicalRecord.h"
#import "Feed.h"

typedef enum ViewTypes
{
    allFeeds = 0,
    allArticles,
    articlesOfAFeed
}ViewType;

@interface MasterViewController () <UIAlertViewDelegate>
{
    ViewType viewType;
    NSMutableArray *feeds;
    NSMutableArray *articles;
}

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

NSString * const feedCell = @"FeedCell";
NSString * const articleCell = @"ArticleCell";
NSString * const addAlertTitle = @"Add new feed";
NSString * const addButtonTitle = @"Add";
NSString * const cancelButtonTitle = @"Cancel";
NSString * const nameTextFieldPlaceholder = @"Enter the name of the feed";
NSString * const addressTextFieldPlaceholder = @"Enter the address of the feed";
NSString * const name = @"name";



@implementation MasterViewController

-(void)setUpExampleFeeds
{
    feeds = [NSMutableArray array];
    Feed *feed = [Feed MR_createEntity];
    feed.name = @"Apple news";
    feed.feedURL = @"http://images.apple.com/main/rss/hotnews/hotnews.rss";
    [feeds addObject:feed];
    
    feed.name = @"Example feed";
    feed.feedURL = @"http://www.feedforall.com/sample.xml";
    [feeds addObject:feed];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self fetchFeeds];
}

- (IBAction)changeSortKey:(id)sender {
    switch ([(UISegmentedControl*)sender selectedSegmentIndex]) {
        case 0: {
            viewType = allFeeds;
            
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector (addFeed:)];
            self.navigationItem.rightBarButtonItem = button;
            
            [self.tableView reloadData];
        }
            break;
        case 1: {
            viewType = allArticles;
            [self.tableView reloadData];
            [self.navigationItem setRightBarButtonItem:nil];
        }
            break;
        default:
            break;
    }
}

-(IBAction)addFeed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:addAlertTitle message:nil delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:addButtonTitle, nil];
    alertView.tag = 0;
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *nameTextField = [alertView textFieldAtIndex:0];
    UITextField *addressTextField = [alertView textFieldAtIndex:1];
    addressTextField.secureTextEntry = NO;
    
    nameTextField.placeholder = nameTextFieldPlaceholder;
    addressTextField.placeholder = addressTextFieldPlaceholder;
    
    alertView.delegate = self;
    [alertView show];
}

-(void)showAllArticles
{
    viewType = allArticles;
    [self.navigationItem setRightBarButtonItem:nil];
    
    [self.tableView reloadData];
}

#pragma mark - CoreData

-(void)saveContext {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"You successfully saved your context.");
        } else if (error) {
            NSLog(@"Error saving context: %@", error.description);
        }
    }];
}

-(void)fetchFeeds
{
    feeds = [[Feed MR_findAllSortedBy:name ascending: YES] mutableCopy];
}

#pragma mark - AlertView

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0)
    {
        if (buttonIndex == 1)
        {
            UITextField *textField = [alertView textFieldAtIndex:0];
            Feed * feed = [Feed MR_createEntity];
            feed.name = textField.text;
            textField = [alertView textFieldAtIndex:1];
            feed.feedURL = textField.text;
            
            [feeds addObject:feed];
            [self saveContext];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (viewType) {
        case allFeeds:
            return [feeds count];
            break;
            
        default:
            return [articles count];
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (viewType) {
        case allFeeds:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:feedCell];
            Feed *feed = [feeds objectAtIndex:indexPath.row];
            cell.textLabel.text = feed.name;
            
            return cell;
        }
            
        default:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:articleCell];
            
            return cell;
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (viewType == allFeeds)
    {
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[NSManagedObjectContext MR_defaultContext] deleteObject:[feeds objectAtIndex:indexPath.row]];
        [feeds removeObjectAtIndex:indexPath.row];
        [self saveContext];
        [self.tableView reloadData];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (viewType == allFeeds)
    {
        viewType = articlesOfAFeed;
        self.segmentedControl.selectedSegmentIndex = 1;
        [self.navigationItem setRightBarButtonItem:nil];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Show all" style:UIBarButtonItemStylePlain target:self action:@selector (showAllArticles)];
        self.navigationItem.rightBarButtonItem = button;
        
        [self.tableView reloadData];
    }
}


@end
