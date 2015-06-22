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
#import "Article.h"
#import "FeedCell.h"
#import "ArticleCell.h"

typedef enum ViewTypes
{
    allFeeds = 0,
    allArticles,
    articlesOfAFeed
}ViewType;

@interface MasterViewController () <UIAlertViewDelegate, NSXMLParserDelegate, NSFetchedResultsControllerDelegate>
{
    ViewType viewType;
    NSMutableArray *feeds;
    NSMutableArray *articles;
    NSString *currentElement;
    NSMutableString *currentTitle;
    NSMutableString *currentImage;
    NSMutableString *currentPublicationDate;
    NSMutableString *currentLink;
    NSMutableString *currentArticleDescription;
    NSString *feedName;
    Article *currentArticle;
    Feed *currentFeed;
    Boolean shouldAutodetectName;
    Boolean inImageElement;
    Boolean inItemElement;
    NSInteger indexOfCellBeingEdited;
    NSArray *oldArticles;
    
    NSFetchedResultsController *fetchedResultsController;
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
NSString * const name = @"name";
NSString * const alertMessage = @"Leave name blank to autodetect.";
NSString * const showAll = @"Show All";
NSString * const itemElement = @"item";
NSString * const linkElement = @"link";
NSString * const titleElement = @"title";
NSString * const descriptionElement = @"description";
NSString * const publicationDateElement = @"pubDate";
NSString * const imageElement = @"image";
NSString * const urlElement = @"url";
NSString * const rfc822DateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
NSString * const publicationDate = @"publicationDate";
NSString * const showArticleFromArticlesOfAFeedSegue = @"showArticleFromArticlesOfAFeed";
NSString * const showArticleFromAllArticlesSegue = @"showArticleFromAllArticles";
NSString * const invalidURL = @"Invalid address";
NSString * const okButtonTitle = @"Ok";


@implementation MasterViewController

-(void)setUpExampleFeeds
{
    feeds = [NSMutableArray array];
    Feed *feed = [Feed MR_createEntity];
    feed.name = @"Apple news";
    feed.feedURL = @"http://images.apple.com/main/rss/hotnews/hotnews.rss";
    [feeds addObject:feed];
    
    feed = [Feed MR_createEntity];
    feed.name = @"Example feed";
    feed.feedURL = @"http://www.feedforall.com/sample.xml";
    feed.image = @"http://www.feedforall.com/ffalogo48x48.gif";
    [feeds addObject:feed];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.topItem.title = feedsString;
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector (addFeed:)];
    self.navigationItem.rightBarButtonItem = button;
    
    [self fetchFeeds];
    shouldAutodetectName = NO;
    
    for (Feed *feed in feeds)
    {
        currentFeed = feed;
        feed.unreadArticleCount = 0;
        [self parseForArticles:feed];
        [self countUnreadArticles:feed];
    }
    [self saveContext];
    
    
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Feed"];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    [fetchedResultsController setDelegate:self];
    
    NSError *error;
    
    [fetchedResultsController performFetch:&error];
    
    if (!error)
    {
        NSLog(@"%@", error);
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

-(void)countUnreadArticles:(Feed *)feed
{
    feed.unreadArticleCount = [NSNumber numberWithInt:0];
    
    NSArray *articleArray =[feed.articles allObjects];
    for (Article *article in articleArray)
    {
        if ([article.isUnread isEqualToNumber: [NSNumber numberWithInt:1]])
        {
            feed.unreadArticleCount = [NSNumber numberWithLong:[feed.unreadArticleCount integerValue] + 1l];
        }
    }
}

-(void)refresh:(id)sender
{
    for (Feed *feed in feeds)
    {
        currentFeed = feed;
        [self parseForArticles:feed];
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
            
            for (Feed *feed in feeds)
            {
                [self countUnreadArticles:feed];
            }
            
            [self.tableView reloadData];
        }
            break;
        case 1: {
            [self showAllArticles];
        }
            break;
        default:
            break;
    }
}

-(IBAction)editCell:(id)sender
{
    UIButton *button = (UIButton *) sender;
    indexOfCellBeingEdited = button.tag;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:editAlertTitle message:alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:editButtonTitle, nil];
    alertView.tag = 1;
    
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *nameTextField = [alertView textFieldAtIndex:0];
    UITextField *addressTextField = [alertView textFieldAtIndex:1];
    addressTextField.secureTextEntry = NO;
    
    nameTextField.placeholder = nameTextFieldPlaceholder;
    addressTextField.placeholder = addressTextFieldPlaceholder;
    
    nameTextField.text = [[feeds objectAtIndex:indexOfCellBeingEdited] name];
    addressTextField.text = [[feeds objectAtIndex:indexOfCellBeingEdited] feedURL];
    
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
    [self getAllArticles];
    
    self.navigationController.navigationBar.topItem.title = allArticlesString;
    
    [self setRefreshControl:nil];
    
    [self.tableView reloadData];
}

-(void)parseForArticles:(Feed *)feed
{
    oldArticles = [feed.articles allObjects];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:feed.feedURL]];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    if (shouldAutodetectName)
    {
        feed.name = feedName;
    }
}

-(void)getArticlesOfFeedAtIndex:(NSIndexPath *) indexPath
{
    Feed *feed = [feeds objectAtIndex:indexPath.row];
    
    articles = [[feed.articles allObjects] mutableCopy];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:publicationDate ascending:NO comparator:^(id obj1, id obj2) {
        NSDate *date1 = obj1;
        NSDate *date2 = obj2;
        
        return [date1 compare:date2];
    }];
                                        
    articles = [[articles sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] mutableCopy];
    for (Article *article in articles)
    {
        NSLog(@"%@ %@", article.title, article.publicationDate);
    }
}

-(void)getAllArticles
{
    articles = [NSMutableArray array];
    for (Feed *feed in feeds)
    {
        [articles addObjectsFromArray:[feed.articles allObjects]];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:publicationDate ascending:NO comparator:^(id obj1, id obj2) {
        NSDate *date1 = obj1;
        NSDate *date2 = obj2;
        
        return [date1 compare:date2];
    }];
    
    articles = [[articles sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] mutableCopy];
}

-(NSString *)removeTrailingWhitespaceFromString:(NSString *)string
{
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+$" options:NSRegularExpressionCaseInsensitive error:&error];
    
    if (!error)
    {
        string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    }
    
    return string;
}

#pragma mark - ParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    currentElement = elementName;
    
    if ([currentElement isEqualToString:itemElement]) {
        
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
    
    if ([currentElement isEqualToString:imageElement])
    {
        currentImage = [[NSMutableString alloc] init];
        inImageElement = YES;
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([currentElement isEqualToString:titleElement] && !inImageElement) {
        [currentTitle appendString:string];
    }
    else if ([currentElement isEqualToString:linkElement]) {
        [currentLink appendString:string];
    }
    else if ([currentElement isEqualToString:publicationDateElement])
    {
        [currentPublicationDate appendString:string];
    }
    else if ([currentElement isEqualToString:descriptionElement])
    {
        [currentArticleDescription appendString:string];
    }
    else if (inImageElement)
        if ([currentElement isEqualToString:urlElement])
        {
            [currentImage appendString:string];
        }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
    
    if ([elementName isEqualToString:itemElement]) {
        currentTitle = [[self removeTrailingWhitespaceFromString:currentTitle] mutableCopy];
        currentArticleDescription = [[self removeTrailingWhitespaceFromString:currentArticleDescription] mutableCopy];
        currentLink = [[self removeTrailingWhitespaceFromString:currentLink] mutableCopy];
        
        currentTitle = [[currentTitle stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        currentArticleDescription = [[currentArticleDescription stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        currentLink = [[currentLink stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        
        currentArticle.title = currentTitle;
        currentArticle.articleDescription = currentArticleDescription;
        currentArticle.link = currentLink;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:rfc822DateFormat];
        currentPublicationDate = [[currentPublicationDate stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        currentArticle.publicationDate = [formatter dateFromString:currentPublicationDate];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.link contains %@",currentArticle.link];
        NSArray *resultArray = [oldArticles filteredArrayUsingPredicate:predicate];
        
        if (resultArray.count != 0)
        {
            [currentArticle MR_deleteEntity];
        }
        else{
            currentArticle.isUnread = [NSNumber numberWithInt:1];
            [currentFeed addArticlesObject:currentArticle];
        }
        inItemElement = NO;
    }
    
    if (!inItemElement && !inImageElement && shouldAutodetectName && [elementName isEqualToString:titleElement])
    {
        currentTitle = [[self removeTrailingWhitespaceFromString:currentTitle] mutableCopy];
        currentTitle = [[currentTitle stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        feedName = [currentTitle copy];
    }
    
    if ([elementName isEqualToString:imageElement])
    {
        currentImage = [[self removeTrailingWhitespaceFromString:currentImage] mutableCopy];
        currentImage = [[currentImage stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
        currentFeed.image = currentImage;
        inImageElement = NO;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
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

-(void)fetchFeeds
{
    feeds = [[Feed MR_findAllSortedBy:name ascending: YES] mutableCopy];
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
                    currentFeed = [Feed MR_createEntity];
                    currentFeed.feedURL = textField.text;
                    textField = [alertView textFieldAtIndex:0];
                    if (textField.text.length == 0)
                    {
                        shouldAutodetectName = YES;
                    }
                    else
                    {
                        currentFeed.name = textField.text;
                        shouldAutodetectName = NO;
                    }
                    
                    [self parseForArticles:currentFeed];
                    [self countUnreadArticles:currentFeed];
                    [feeds addObject:currentFeed];
                    [self.tableView reloadData];
                    [self saveContext];
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
                    currentFeed = [feeds objectAtIndex:indexOfCellBeingEdited];
                    if (![currentFeed.feedURL isEqualToString:textField.text])
                    {
                        [currentFeed MR_deleteEntity];
                        currentFeed = [Feed MR_createEntity];
                        currentFeed.feedURL = textField.text;
                    }
                    textField = [alertView textFieldAtIndex:0];
                    if (textField.text.length == 0)
                    {
                        shouldAutodetectName = YES;
                    }
                    else
                    {
                        currentFeed.name = textField.text;
                        shouldAutodetectName = NO;
                    }
                    
                    [self parseForArticles:currentFeed];
                    [self countUnreadArticles:currentFeed];
                    
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
            FeedCell *cell = [tableView dequeueReusableCellWithIdentifier:feedCell];
            Feed *feed = [feeds objectAtIndex:indexPath.row];
            cell.nameLabel.text = feed.name;
            cell.editButton.tag = indexPath.row;
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
            
            return cell;
        }
            
        case allArticles:
        {
            ArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:articleCell];
            NSString *titleText = [(Article *) [articles objectAtIndex:indexPath.row] title];
            NSString *descriptionText = [(Article *) [articles objectAtIndex:indexPath.row] articleDescription];
            
            cell.titleLabel.text = titleText;
            cell.descriptionLabel.text = descriptionText;
            
            if ([[(Article *) [articles objectAtIndex:indexPath.row] isUnread] isEqualToNumber: [NSNumber numberWithInt:1]])
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
            CGFloat height = [self calculateHeightOfText:titleText font:[UIFont boldSystemFontOfSize:19.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
            
            [titleLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[titleLabel(==%f)]", height] options:0 metrics:nil views:NSDictionaryOfVariableBindings(titleLabel)]];
            
            return cell;
        }
        case articlesOfAFeed:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellString];
            cell.textLabel.text = [(Article *) [articles objectAtIndex:indexPath.row] title];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            
            if ([[(Article *) [articles objectAtIndex:indexPath.row] isUnread] isEqualToNumber: [NSNumber numberWithInt:1]])
            {
                cell.textLabel.textColor = [UIColor redColor];
            }
            else
            {
                cell.textLabel.textColor = [UIColor blackColor];
            }
            
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
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:showAll style:UIBarButtonItemStylePlain target:self action:@selector (showAllArticles)];
        self.navigationItem.rightBarButtonItem = button;
        
        [self getArticlesOfFeedAtIndex:indexPath];
        
        self.navigationController.navigationBar.topItem.title = [(Feed *) [feeds objectAtIndex:indexPath.row] name];
        
        [self setRefreshControl:nil];
        
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
            [NSString stringWithFormat:@"%li",[[(Feed *) [feeds objectAtIndex:indexPath.row] unreadArticleCount] integerValue]];
            CGFloat widthOfNewArticleCount = [self calculateWidthtOfText:[NSString stringWithFormat:@"%li",[[(Feed *) [feeds objectAtIndex:indexPath.row] unreadArticleCount] integerValue]] font:[UIFont systemFontOfSize:17.0f] maximumHeightOfText:CGFLOAT_MAX paragraphStyle:paragraphStyle];
            if (widthOfNewArticleCount > 110.f)
            {
                widthOfNewArticleCount = 110.0f;
            }
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            height = [self calculateHeightOfText:[(Feed *) [feeds objectAtIndex:indexPath.row] name] font:[UIFont systemFontOfSize:17.0f] maximumWidthOfText:self.view.bounds.size.width - 110.0f - widthOfNewArticleCount paragraphStyle:paragraphStyle];
            break;
        }
        case allArticles:
        {
            NSString *descriptionText = [[(Article *) [articles objectAtIndex:indexPath.row] articleDescription] copy];
            if ([descriptionText length] != 0)
            {
                if ([descriptionText length] > 100)
                {
                    descriptionText = [descriptionText substringToIndex:100];
                }
                paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
                height = [self calculateHeightOfText:descriptionText font:[UIFont systemFontOfSize:17.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
            }
            else
            {
                height = 0.0f;
            }
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            height += [self calculateHeightOfText:[(Article *) [articles objectAtIndex:indexPath.row] title] font:[UIFont boldSystemFontOfSize:19.0f] maximumWidthOfText:self.tableView.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
            height = height + 8.0f;
            
            break;
        }
        case articlesOfAFeed:
        {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            height = [self calculateHeightOfText:[(Article *) [articles objectAtIndex:indexPath.row] title] font:[UIFont systemFontOfSize:17.0f] maximumWidthOfText:self.view.bounds.size.width - 16.0f paragraphStyle:paragraphStyle];
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
        detailView.articles = articles;
        [self saveContext];
    }
}

@end
