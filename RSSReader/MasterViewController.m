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
#import "Feed+Counter.h"
#import "FeedParser.h"
#import "Article.h"
#import "FeedCell.h"
#import "ArticleCell.h"
#import "TitleCell.h"

typedef enum ViewTypes
{
    allFeeds = 0,
    allArticles,
    articlesOfAFeed
}ViewType;

@interface MasterViewController () <UIAlertViewDelegate, NSFetchedResultsControllerDelegate>
{
    ViewType viewType;
    NSIndexPath *indexOfCellBeingEdited;
    
    NSFetchedResultsController *fetchedResultsController;
    NSString *selectedFeedURL;
}

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

NSString * const feedsString = @"Feeds";
NSString * const allArticlesString = @"All articles";
NSString * const feedCell = @"FeedCell";
NSString * const articleCell = @"ArticleCell";
NSString * const cellString = @"Cell";
NSString * const addAlertTitle = @"Add new feed";
NSString * const editAlertTitle = @"Edit feed";
NSString * const addButtonTitle = @"Add";
NSString * const editButtonTitle = @"Save changes";
NSString * const cancelButtonTitle = @"Cancel";
NSString * const nameTextFieldPlaceholder = @"Enter the name of the feed";
NSString * const addressTextFieldPlaceholder = @"Enter the address of the feed";
NSString * const publicationDate = @"publicationDate";
NSString * const name = @"name";
NSString * const alertMessage = @"Leave name blank to autodetect.";
NSString * const showAll = @"Show All";
NSString * const showArticleFromArticlesOfAFeedSegue = @"showArticleFromArticlesOfAFeed";
NSString * const showArticleFromAllArticlesSegue = @"showArticleFromAllArticles";
NSString * const invalidURL = @"Invalid address";
NSString * const okButtonTitle = @"Ok";


@implementation MasterViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = feedsString;
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector (addFeed:)];
    self.navigationItem.rightBarButtonItem = button;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
    
    [self setUpFetchedResultsController];
    
    [self refresh:self];
}

-(void)setUpFetchedResultsController
{
    NSFetchRequest *fetchRequest;
    NSSortDescriptor *sortDescriptor;
    
    if (viewType == allFeeds)
    {
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Feed"];
        
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    }
    else
    {
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Article"];
        sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:publicationDate ascending:NO];
        
        if (viewType == articlesOfAFeed)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"feed.feedURL == %@",selectedFeedURL];
            
            [fetchRequest setPredicate:predicate];
        }
    }
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[NSManagedObjectContext MR_defaultContext] sectionNameKeyPath:nil cacheName:nil];
    
    [fetchedResultsController setDelegate:self];
    
    NSError *error;
    
    [fetchedResultsController performFetch:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
    }
}

-(void)refresh:(id)sender
{
    NSArray *feeds = [fetchedResultsController fetchedObjects];
    FeedParser *parser = [[FeedParser alloc] init];
    
    for (Feed *feed in feeds)
    {
        [parser parseFeed:feed andShouldAutoDetectName:NO];
    }
    [self saveContext];
    
    [self.refreshControl endRefreshing];
}

- (IBAction)changeSortKey:(id)sender
{
    switch ([(UISegmentedControl*)sender selectedSegmentIndex]) {
        case 0: {
            viewType = allFeeds;
            
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector (addFeed:)];
            self.navigationItem.rightBarButtonItem = button;
            
            self.navigationController.navigationBar.topItem.title = feedsString;
            
            UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
            [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
            [self setRefreshControl:refreshControl];
            
            [self setUpFetchedResultsController];
            
            NSArray *feeds = [fetchedResultsController fetchedObjects];
            
            for (Feed *feed in feeds)
            {
                [feed countUnreadArticles];
            }
            
            [self saveContext];
            
            [self.tableView reloadData];
        }
            break;
        case 1: {
            [self showAllArticles];
        }
            break;
    }
}

-(IBAction)editCell:(id)sender
{
    UIButton *button = (UIButton *) sender;
    indexOfCellBeingEdited = [NSIndexPath indexPathForRow:button.tag inSection:0];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:editAlertTitle message:alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:editButtonTitle, nil];
    alertView.tag = 1;
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *nameTextField = [alertView textFieldAtIndex:0];
    UITextField *addressTextField = [alertView textFieldAtIndex:1];
    addressTextField.secureTextEntry = NO;
    
    nameTextField.placeholder = nameTextFieldPlaceholder;
    addressTextField.placeholder = addressTextFieldPlaceholder;
    
    nameTextField.text = [[fetchedResultsController objectAtIndexPath:indexOfCellBeingEdited] name];
    addressTextField.text = [[fetchedResultsController objectAtIndexPath:indexOfCellBeingEdited] feedURL];
    
    [alertView show];
}

-(void)addFeed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:addAlertTitle message:alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:addButtonTitle, nil];
    alertView.tag = 0;
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *nameTextField = [alertView textFieldAtIndex:0];
    UITextField *addressTextField = [alertView textFieldAtIndex:1];
    addressTextField.secureTextEntry = NO;
    
    nameTextField.placeholder = nameTextFieldPlaceholder;
    addressTextField.placeholder = addressTextFieldPlaceholder;
    
    [alertView show];
}

-(void)showAllArticles
{
    viewType = allArticles;
    [self.navigationItem setRightBarButtonItem:nil];
    [self setUpFetchedResultsController];
    
    self.navigationController.navigationBar.topItem.title = allArticlesString;
    
    [self setRefreshControl:nil];
    
    [self.tableView reloadData];
}

#pragma mark - CoreData

-(void)saveContext
{
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"Error saving context: %@", error.description);
        }
    }];
}

#pragma mark - AlertView

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case 0:
        {
            if (buttonIndex == 1)
            {
                UITextField *textField = [alertView textFieldAtIndex:1];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:textField.text]];
                if ([NSURLConnection canHandleRequest:request])
                {
                    Feed *currentFeed = [Feed MR_createEntity];
                    currentFeed.feedURL = textField.text;
                    textField = [alertView textFieldAtIndex:0];
                    Boolean shouldAutodetectName;
                    if (textField.text.length == 0 || !textField.text.length)
                    {
                        shouldAutodetectName = YES;
                    }
                    else
                    {
                        currentFeed.name = textField.text;
                        shouldAutodetectName = NO;
                    }
                    
                    FeedParser *parser = [[FeedParser alloc] init];
                    [parser parseFeed:currentFeed andShouldAutoDetectName:shouldAutodetectName];
                    [self saveContext];
                    
                    [self setUpFetchedResultsController];
                    [self.tableView reloadData];
                }
                else
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:invalidURL message:nil delegate:nil cancelButtonTitle:okButtonTitle otherButtonTitles: nil];
                    
                    [alert show];
                }
            }
            break;
        }
        case 1:
        {
            if (buttonIndex == 1)
            {
                UITextField *textField = [alertView textFieldAtIndex:1];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:textField.text]];
                if ([NSURLConnection canHandleRequest:request])
                {
                    Feed *currentFeed = [fetchedResultsController objectAtIndexPath:indexOfCellBeingEdited];
                    if (![currentFeed.feedURL isEqualToString:textField.text])
                    {
                        [currentFeed MR_deleteEntity];
                        currentFeed = [Feed MR_createEntity];
                        currentFeed.feedURL = textField.text;
                    }
                    textField = [alertView textFieldAtIndex:0];
                    Boolean shouldAutodetectName;
                    
                    if (textField.text.length == 0 || !textField.text.length)
                    {
                        shouldAutodetectName = YES;
                    }
                    else
                    {
                        currentFeed.name = textField.text;
                        shouldAutodetectName = NO;
                    }
                    
                    FeedParser *parser = [[FeedParser alloc] init];
                    [parser parseFeed:currentFeed andShouldAutoDetectName:shouldAutodetectName];
                    
                    [self saveContext];
                }
                else
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:invalidURL message:nil delegate:nil cancelButtonTitle:okButtonTitle otherButtonTitles: nil];
                    
                    [alert show];
                }
            }
            
        }
    }
    
}

#pragma mark - TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[fetchedResultsController sections] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

-(void)configureFeedCell:(FeedCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Feed *feed = (Feed *) [fetchedResultsController objectAtIndexPath:indexPath];
    [cell.nameLabel setText:feed.name];
    [cell.unreadArticlesCountLabel setText:[NSString stringWithFormat:@"%li", (long)[feed.unreadArticleCount integerValue]]];
    [cell.editButton setTag:indexPath.row];
    
    if ([feed.unreadArticleCount integerValue] != 0)
    {
        cell.unreadArticlesCountLabel.text = [NSString stringWithFormat:@"%li", [feed.unreadArticleCount integerValue]];
        cell.unreadArticlesCountLabel.hidden = NO;
    }
    else
    {
        cell.unreadArticlesCountLabel.hidden = YES;
    }
    
    if (feed.image.length != 0)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^
                       {
                           NSURL *url = [NSURL URLWithString:[feed.image stringByTrimmingCharactersInSet:
                                                              [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                           NSURLRequest *request = [NSURLRequest requestWithURL:url];
                           
                           NSURLResponse *response;
                           NSError *error;
                           NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                                returningResponse:&response
                                                                            error:&error];
                           if (!error)
                           {
                               dispatch_async(dispatch_get_main_queue(), ^
                                              {
                                                  cell.image.image = [UIImage imageWithData:data];
                                              });
                           }
                           else
                           {
                               NSLog(@"Could not download icon with error: %@", error);
                           }
                       });
    }
    else
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cell.image.image = blank;
    }
}

-(void)configureArticleCell:(ArticleCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Article *article = (Article *) [fetchedResultsController objectAtIndexPath:indexPath];
    [cell.titleLabel setText:article.title];
    [cell.descriptionLabel setText:article.articleDescription];
    
    if ([article.isUnread isEqualToNumber: [NSNumber numberWithInt:1]])
    {
        cell.titleLabel.textColor = [UIColor redColor];
    }
    else
    {
        cell.titleLabel.textColor = [UIColor blackColor];
    }
    
    UILabel *titleLabel = cell.titleLabel;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = titleLabel.lineBreakMode;
    CGFloat height = [self calculateHeightOfText:article.title font:[UIFont boldSystemFontOfSize:19.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
    height = ceil(height);
    [titleLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[titleLabel(==%f@1000)]", height] options:0 metrics:nil views:NSDictionaryOfVariableBindings(titleLabel)]];
    if (article.description
        == 0)
    {
        cell.descriptionLabel.hidden = YES;
    }
    else
    {
        cell.descriptionLabel.hidden = NO;
    }
}

-(void)configureTitleCell:(TitleCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Article *article = (Article *) [fetchedResultsController objectAtIndexPath:indexPath];
    [cell.titleLabel setText: article.title];
    
    if ([article.isUnread isEqualToNumber: [NSNumber numberWithInt:1]])
    {
        cell.titleLabel.textColor = [UIColor redColor];
    }
    else
    {
        cell.titleLabel.textColor = [UIColor blackColor];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (viewType) {
        case allFeeds:
        {
            FeedCell *cell = [self.tableView dequeueReusableCellWithIdentifier:feedCell forIndexPath:indexPath];
            [self configureFeedCell:cell atIndexPath:indexPath];
            
            return cell;
        }
        case allArticles:
        {
            ArticleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:articleCell forIndexPath:indexPath];
            [self configureArticleCell:cell atIndexPath:indexPath];
            
            return cell;
        }
        case articlesOfAFeed:
        {
            TitleCell *cell = [tableView dequeueReusableCellWithIdentifier:cellString forIndexPath:indexPath];
            [self configureTitleCell:cell atIndexPath:indexPath];
            
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
        [[NSManagedObjectContext MR_defaultContext] deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
        
        [self setUpFetchedResultsController];
        
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
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:showAll style:UIBarButtonItemStylePlain target:self action:@selector (showAllArticles)];
        self.navigationItem.rightBarButtonItem = button;
        selectedFeedURL = [(Feed *) [fetchedResultsController objectAtIndexPath:indexPath] feedURL];
        
        
        self.navigationController.navigationBar.topItem.title = [(Feed *) [fetchedResultsController objectAtIndexPath:indexPath] name];
        [self setRefreshControl:nil];
        
        [self setUpFetchedResultsController];
        [self.tableView reloadData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    switch (viewType) {
        case allFeeds:
        {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            Feed *feed = [fetchedResultsController objectAtIndexPath:indexPath];
            CGFloat widthOfNewArticleCount = [self calculateWidthtOfText:[NSString stringWithFormat:@"%li",[feed.unreadArticleCount integerValue]] font:[UIFont systemFontOfSize:17.0f] maximumHeightOfText:CGFLOAT_MAX paragraphStyle:paragraphStyle];
            if (widthOfNewArticleCount > 110.f)
            {
                widthOfNewArticleCount = 110.0f;
            }
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            height = [self calculateHeightOfText:feed.name font:[UIFont systemFontOfSize:17.0f] maximumWidthOfText:self.view.bounds.size.width - 110.0f - widthOfNewArticleCount paragraphStyle:paragraphStyle];
            break;
        }
        case allArticles:
        {
            Article *article = [fetchedResultsController objectAtIndexPath:indexPath];
            NSString *descriptionText = [article.articleDescription copy];
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            
            height = [self calculateHeightOfText:article.title font:[UIFont boldSystemFontOfSize:19.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
            
            if ([descriptionText length] != 0)
            {
                if ([descriptionText length] > 100)
                {
                    descriptionText = [descriptionText substringToIndex:100];
                }
                height += 8.0f;
                
                CGFloat descriptionHeight = [self calculateHeightOfText:descriptionText font:[UIFont systemFontOfSize:17.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
                height += descriptionHeight;
            }
            
            break;
        }
        case articlesOfAFeed:
        {
            Article *article = [fetchedResultsController objectAtIndexPath:indexPath];
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            height = [self calculateHeightOfText:article.title font:[UIFont boldSystemFontOfSize:19.0f] maximumWidthOfText:self.view.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
            break;
        }
    }
    height = height + 16.0f;
    height = ceil(height);
    return height;
}

-(CGFloat)calculateHeightOfText:(NSString *)text font:(UIFont *)font maximumWidthOfText:(CGFloat)width paragraphStyle:(NSMutableParagraphStyle *)paragraphStyle
{
    CGSize size = CGSizeMake(width, CGFLOAT_MAX);
    CGRect textRect = [text boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle}
                                         context:nil];
    
    return textRect.size.height;
}

-(CGFloat)calculateWidthtOfText:(NSString *)text font:(UIFont *)font maximumHeightOfText:(CGFloat)height paragraphStyle:(NSMutableParagraphStyle *)paragraphStyle
{
    CGSize size = CGSizeMake(CGFLOAT_MAX, height);
    CGRect textRect = [text boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle}
                                         context:nil];
    
    return textRect.size.width;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:showArticleFromAllArticlesSegue] || [segue.identifier isEqualToString:showArticleFromArticlesOfAFeedSegue])
    {
        DetailViewController *detailView = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        detailView.indexPath = indexPath;
        detailView.fetchedResultsController = fetchedResultsController;
        [self saveContext];
    }
}

#pragma mark - FetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            switch (viewType) {
                case allFeeds:
                {
                    [self configureFeedCell:(FeedCell *) [self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                    break;
                }
                case allArticles:
                {
                    [self configureArticleCell:(ArticleCell *) [self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                   break;
                }
                case articlesOfAFeed:
                {
                    [self configureTitleCell:(TitleCell *) [self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                    break;
                }
            }
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

@end
