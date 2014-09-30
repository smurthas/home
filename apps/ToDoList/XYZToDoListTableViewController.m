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
    HMQuery *query = [HMQuery objectQueryWithCollectionName:self.listItem[@"_id"]];
    [query whereKey:@"logged" equalTo:@NO];
//    [query whereKey:@"list" equalTo:self.listItem[@"name"]];
    
    NSLog(@"my list name: %@", self.listItem[@"name"]);
    [self.account findInBackground:query block:^(NSArray *objects, NSError *error) {
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
//        source.toDoItem[@"list"] = self.listItem[@"name"];
        source.toDoItem[@"_grants"] = [[NSMutableDictionary alloc] init];
        source.toDoItem[@"_grants"][[self.account getAccountID]] = [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];
        [self.account saveInBackground:source.toDoItem toCollection:self.listItem[@"_id"]];
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
    NSString *toAccountID = @"ea975416-d59f-4f70-aec8-2a78c67ebc24";
    
    
    // enable the toAccountID to create objects in this collection
    self.listItem[@"_grants"][toAccountID] = [NSMutableDictionary dictionaryWithDictionary:@{
            @"createObjects": @YES,
            @"modifyCollection": @YES
        }];
    [self.account saveCollection:self.listItem block:^(NSDictionary *updateCollection, NSError *error) {
        
        
        // grant permission for all items in the list
        
        for (NSMutableDictionary* todo in self.toDoItems) {
            ((NSMutableDictionary*)todo[@"_grants"])[toAccountID] = [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];
        }
        
        NSString *batchURL = [[[[self.account URLStringForCollection:self.listItem[@"_id"]] stringByAppendingString:@"__batch"] stringByAppendingString:@"?token="] stringByAppendingString:[self.account getToken]];
        
        
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager PUT:batchURL parameters:self.toDoItems success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            
            // TODO: update the _updatedAt timestamps
            
            
            // send the other account a notification with my AccountID, List Name, CollectionID
            // TODO: send it
            
            [self.account createGrantWithAccountID:toAccountID block:^(NSDictionary *grant, NSError *error) {
                NSString *resourceURL = [[[self.account URLStringForCollection:self.listItem[@"_id"]] stringByAppendingString:@"?token="] stringByAppendingString:grant[@"token"]];
                NSLog(@"sharing resourceURL: %@", resourceURL);
                
/*                NSDictionary *invitation = @{
                    @"token": grant[@"token"],
                    @"uri": resourceURL
                };
                
                NSLog(@"sharing: %@", invitation);*/
            }];
            
            //callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            //callbackBlock(nil, error);
        }];
        
    }];
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
    
    NSString *collectionID = self.listItem[@"_id"];
    
    [self.account deleteInBackground:toDoItem fromCollection:collectionID];
    
    NSLog(@"Deleted row.");
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableDictionary *tappedItem = [self.toDoItems objectAtIndex:indexPath.row];
    tappedItem[@"completed"] = @(![tappedItem[@"completed"] boolValue]);
    
    NSString *collectionID = self.listItem[@"_id"];
    [self.account saveInBackground:tappedItem toCollection:collectionID];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
