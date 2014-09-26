//
//  XYZListsListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/20/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZListsListTableViewController.h"
#import "XYZToDoListTableViewController.h"
#import "XYZAddListViewController.h"

#import "HMAccount.h"
#import "HMQuery.h"

@interface XYZListsListTableViewController ()

@property NSMutableArray *lists;

@end

@implementation XYZListsListTableViewController


- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    HMQuery *query = [HMQuery collectionQuery];
    [query whereKey:@"type" equalTo:@"list"];
    [query findInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"objects %@", objects);
        NSLog(@"error %@", error);
        if (error == nil) {
            self.lists = [[NSMutableArray alloc] initWithArray:objects];
            NSLog(@"listItems %@", self.lists);
            [self.tableView reloadData];
        }
        callbackBlock(error);
    }];
}

- (IBAction)login:(id)sender {
    NSString *publicKey = @"myTodos";
    
    [HMAccount loginWithPublicKey:publicKey callbackURI:@"todos://com.sms.todos/auth_complete"];
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddListViewController *source = [segue sourceViewController];
    NSLog(@"listItem: %@", source.listItem);
    if (source.listItem != nil) {
        [self.lists addObject:source.listItem];
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

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"self.lists class %@", [self.lists class]);
    NSLog(@"self.lists %@", self.lists);
    NSLog(@"self.lists.count %@", @([self.lists count]));
    return [self.lists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListListPrototypeCell" forIndexPath:indexPath];
    
    NSLog(@"self.lists class %@", [self.lists class]);
    NSLog(@"self.lists %@", self.lists);
    NSLog(@"self.lists.count %@", @([self.lists count]));
    cell.textLabel.text = [self.lists objectAtIndex:indexPath.row][@"name"];
    // Configure the cell...
    
    NSLog(@"returning cell");
    return cell;
}


- (IBAction)refresh:(id)sender
{
    NSLog(@"Refreshing");
    [self loadInitialData:^(NSError *error) {
        [(UIRefreshControl *)sender endRefreshing];
    }];
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"preparing for segue");
    
    if ([[segue destinationViewController] class] == [XYZToDoListTableViewController class]) {
        XYZToDoListTableViewController *tvc = (XYZToDoListTableViewController*)[segue destinationViewController];
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        
        tvc.listItem = [self.lists objectAtIndex:path.row];
    }
    
}


@end
