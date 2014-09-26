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

@end

@implementation XYZToDoListTableViewController

- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    HMQuery *query = [HMQuery objectQueryWithClassName:@"todos"];
    [query whereKey:@"logged" equalTo:@NO];
    [query whereKey:@"list" equalTo:self.listItem[@"name"]];
    
    NSLog(@"my list name: %@", self.listItem[@"name"]);
    [query findInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"objects count: %@", @([objects count]));
        if (error == nil) {
            self.toDoItems = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
        NSLog(@"self.toDoItems count: %@", @([self.toDoItems count]));
        callbackBlock(error);
    }];
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddToDoItemViewController *source = [segue sourceViewController];
    
    NSLog(@"todoItem: %@", source.toDoItem);
    if (source.toDoItem != nil) {
        source.toDoItem[@"list"] = self.listItem[@"name"];
        [[HMAccount currentAccount] saveInBackground:source.toDoItem toCollection:@"todos"];
        [self.toDoItems addObject:source.toDoItem];
        [self.tableView reloadData];
    }
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
    
    [self loadInitialData:^(NSError *error) {
        NSLog(@"reloaded data");
    }];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
    
//    self.toDoItems = [[NSMutableArray alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)shareList:(id)sender {
    NSLog(@"sharing list %@", self.listItem[@"name"]);
    // pick or enter user info
    HMAccount *toAccount = [HMAccount accountWithBaseUrl:@"http://localhost:2751" publicKey:@"blargh"];
    HMAccount *account = [HMAccount currentAccount];
    [account createGrantWithAccount:toAccount forResource:self.listItem block:^(NSDictionary *grant, NSError *error) {
        NSMutableArray *collaborators = self.listItem[@"collaborators"];
        if (!collaborators || !collaborators.count) {
            collaborators = [[NSMutableArray alloc] init];
            self.listItem[@"collaborators"] = collaborators;
        }
        
        [collaborators addObject:@{@"pubkey":[toAccount getPublicKey]}];
        
        [account saveInBackground:self.listItem toCollection:@"lists"];
        for (NSMutableDictionary *todo in self.toDoItems) {
            todo[@"acl"] = grant;
            [account saveInBackground:todo toCollection:@"todos"];
        }
        NSDictionary *resource = @{
            @"baseUrl": [account getBaseUrl],
            @"resource": @"/apps/todos"
        };
        
        [account sendGrant:grant toAccount:toAccount forResource:resource];
    }];
    
    
//    [[HMAccount currentAccount] saveInBackground:list toCollection:@"lists"];
    // TODO: grant permission
//    NSMutableArray *ids =
//    [[HMAccount currentAccount] addAuthorization:objectIDs forPublicKey:toAccountPublicKey];
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
