//
//  XYZToDoListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZToDoListTableViewController.h"
#import "XYZAddToDoItemViewController.h"

#import "HMQuery.h"
#import "HMAccount.h"

#import <AFNetworking.h>

@interface XYZToDoListTableViewController ()

@property NSMutableArray *toDoItems;

@end

@implementation XYZToDoListTableViewController

- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    HMQuery *query = [HMQuery queryWithClassName:@"todos"];
    [query whereKey:@"logged" equalTo:@NO];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            [self.toDoItems removeAllObjects];
            [self.toDoItems addObjectsFromArray:objects];
            [self.tableView reloadData];
        }
        callbackBlock(error);
    }];
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddToDoItemViewController *source = [segue sourceViewController];
    NSLog(@"todoItem: %@", source.toDoItem);
    if (source.toDoItem != nil) {
        [self.toDoItems addObject:source.toDoItem];
        [self.tableView reloadData];
    }
}
- (IBAction)login:(id)sender {
    NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoDKn2wdotXbLheSn09g/\nsjAc0rhYb8+KdQDB+zKp9Cq63qJDfR+r8sBn5QLz98LLEWKi7Q3v61Ih9ySUFlqy\nF/dCbugu+Xc8zIxK/8kWk+U1/umc7M6jKD7kw7qhomj/pieEw4UQ9cH0CdxM3U6w\noRSIU/pBix4K1nu8bgpgYzam1e9QTRu+yPw0a0DIsB8Ma7QDFbtcRBm1yi21yQkA\ne1orm2Az7ETZ1pZrGXrcBqcJ/IM3kWSh+mY1earsE1ihgeWueJqBd77zRYI5+0Uf\nN/DxtZUGOIPpKmY20zBgZM4aQO/Il+ZVIRVMJuB0fpimPawFLx8rPyuLbKjjfxyy\n9QIDAQAB\n-----END PUBLIC KEY-----";
    [HMAccount loginWithPublicKey:publicKey callbackURI:@"todos://com.sms.todos/auth_complete"];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toDoItems = [[NSMutableArray alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)refresh:(id)sender
{
    NSLog(@"Refreshing");
    [self loadInitialData:^(NSError *error) {
        [(UIRefreshControl *)sender endRefreshing];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.toDoItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    NSMutableDictionary *toDoItem = [self.toDoItems objectAtIndex:indexPath.row];
    cell.textLabel.text = toDoItem[@"title"];
    
    if ([toDoItem[@"completed"] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES - we will be able to delete all rows
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Perform the real delete action here. Note: you may need to check editing style
    //   if you do not perform delete only.
    
    NSMutableDictionary *toDoItem = [self.toDoItems objectAtIndex:indexPath.row];
    [self.toDoItems removeObjectAtIndex:indexPath.row];
    [self.tableView reloadData];
    [[HMAccount currentAccount] deleteInBackground:toDoItem fromCollection:@"todos"];
    
    NSLog(@"Deleted row.");
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableDictionary *tappedItem = [self.toDoItems objectAtIndex:indexPath.row];
    tappedItem[@"completed"] = @(![tappedItem[@"completed"] boolValue]);
    
    [[HMAccount currentAccount] saveInBackground:tappedItem toCollection:@"todos"];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
