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

@interface MasterViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *feeds;


@end

NSString * const feedCell = @"FeedCell";
NSString * const addAlertTitle = @"Add new feed";
NSString * const addButtonTitle = @"Add";
NSString * const cancelButtonTitle = @"Cancel";
NSString * const nameTextFieldPlaceholder = @"Enter the name of the feed";
NSString * const addressTextFieldPlaceholder = @"Enter the address of the feed";
NSString * const name = @"name";

@implementation MasterViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self fetchFeeds];
}

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
    self.feeds = [[Feed MR_findAllSortedBy:name ascending: YES] mutableCopy];
}

- (IBAction)changeSortKey:(id)sender {
    switch ([(UISegmentedControl*)sender selectedSegmentIndex]) {
        case 0: {
            NSLog(@"Viewing feeds");
            [self.tableView reloadData];
        }
            break;
        case 1: {
            NSLog(@"Viewing articles");
            [self.tableView reloadData];
        }
            break;
        default:
            break;
    }
}

#pragma mark - AlertView

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
            
            [self.feeds addObject:feed];
            [self saveContext];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Number of cells: %li", [self.feeds count]);
    return [self.feeds count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:feedCell];
    Feed *feed = [self.feeds objectAtIndex:indexPath.row];
    cell.textLabel.text = feed.name;
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[NSManagedObjectContext MR_defaultContext] deleteObject:[self.feeds objectAtIndex:indexPath.row]];
        [self.feeds removeObjectAtIndex:indexPath.row];
        [self saveContext];
        [self.tableView reloadData];
    }
}


@end
