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

#import <SlabClient/SlabClient.h>
#import <SlabClient/SLAccount.h>
#import <SlabClient/SLQuery.h>

@interface XYZListsListTableViewController ()

@property NSMutableArray *lists;

@end

@implementation XYZListsListTableViewController

- (void) fillData:(NSArray*)objects fromIndex:(unsigned long)index block:(void (^)(NSError* error))callbackBlock {
    if (index == 0) {
        self.lists = [[NSMutableArray alloc] init];
    }
    if (index == [objects count]) {
        return callbackBlock(nil);
    }

    NSDictionary *list = objects[index];

    if (list[@"pointer"] == nil) {
        [self.lists addObject:list];
        [self fillData:objects fromIndex:(index + 1) block:callbackBlock];
    } else {
        NSString *baseUrl = list[@"pointer"][@"base_url"];
        NSString *accountID = list[@"pointer"][@"account_id"];
        NSDictionary *keyPair = @{
            @"publicKey": [[SLAccount currentAccount] getPublicKey],
            @"secretKey": [[SLAccount currentAccount] getSecretKey]
        };
        SLAccount *account = [SLAccount accountWithBaseUrl:baseUrl appID:@"myTodos" accountID:accountID keyPair:keyPair];

        SLQuery *query = [SLQuery collectionQuery];

        [query whereKey:@"_id" equalTo:list[@"pointer"][@"collection_id"]];
        [[SlabClient sharedClient] findInBackground:query account:account block:^(NSArray *foundObjects, NSError *error) {
            if (error != nil) {
                return callbackBlock(error);
            }
            if (foundObjects.count != 1) {
                NSLog(@"didn't find an object when following pointer: %@", list);
                [self fillData:objects fromIndex:(index + 1) block:callbackBlock];
                return;
            }

            NSMutableDictionary *fullList = (NSMutableDictionary*)foundObjects[0];
            [self.lists addObject:fullList];

            // phew!
            [self fillData:objects fromIndex:(index + 1) block:callbackBlock];
        }];
    }
}

- (void) loadPendingShares:(void (^)(NSError* error))callbackBlock {

    SLQuery *pendingQuery = [SLQuery objectQueryWithCollectionName:@"_pendingSharedLists"];

    [[SlabClient sharedClient] findInBackground:pendingQuery account:[SLAccount currentAccount] block:^(NSArray *pendingCollections, NSError *error) {
        NSLog(@"pendingCollection %@", pendingCollections);

        // TODO: prompt for acceptance of these collections.
        if (error != nil) {
            NSLog(@"error retrieving pending collections %@", error);
            return;
        }

        for (NSDictionary *pendingCollection in pendingCollections) {
            if (pendingCollection[@"collection"] != nil) {
                NSDictionary *collectionInfo = pendingCollection[@"collection"];
                NSMutableDictionary *grants = [[NSMutableDictionary alloc] init];
                grants[[[SLAccount currentAccount] getPublicKey]] = @{
                                                                      @"readAttributes": @YES,
                                                                      @"modifyAttributes": @YES
                                                                      };
                NSMutableDictionary *collectionAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"type": @"list",
                    @"_grants": grants,
                    @"pointer": @{
                        @"base_url": collectionInfo[@"_host"],
                        @"account_id": collectionInfo[@"_accountID"],
                        @"collection_id": collectionInfo[@"_id"]
                    }
                }];

                NSLog(@"collectionAttributes %@", collectionAttributes);
                
                [[SlabClient sharedClient] createCollectionWithAttributes:collectionAttributes
                                                                    block:^(NSDictionary *collection, NSError *error) {
                                                                        
                    [[SlabClient sharedClient] deleteInBackground:pendingCollection fromCollectionID:@"_pendingSharedLists"];
                    
                    [self loadInitialData:^(NSError *error) {
                        NSLog(@"reloaded the root view controller!");
                        callbackBlock(error);
                    }];
                }];
            }
        }
    }];
}

- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    SLQuery *query = [SLQuery collectionQuery];
    [query whereKey:@"type" equalTo:@"list"];
    [query whereKey:@"archived" equalTo:@{@"$ne":@YES}];

    [[SlabClient sharedClient] findInBackground:query account:[SLAccount currentAccount] block:^(NSArray *objects, NSError *error) {
        if (error != nil) return callbackBlock(error);

        NSLog(@"filling with objects: %@", objects);

        [self fillData:objects fromIndex:0 block:^(NSError *error) {
            if (error == nil) [self.tableView reloadData];
            [self loadPendingShares:callbackBlock];
        }];
    }];


}

- (IBAction)login:(id)sender {
    NSString *publicKey = @"myTodos";
    
    [SlabClient loginWithPublicKey:publicKey callbackURI:@"todos://com.sms.todos/auth_complete"];
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddListViewController *source = [segue sourceViewController];
    NSLog(@"listItem: %@", source.listItem);
    if (source.listItem != nil) {
        [self.lists insertObject:source.listItem atIndex:0];
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
    return [self.lists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListListPrototypeCell" forIndexPath:indexPath];

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




// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source

        NSMutableDictionary *list = self.lists[indexPath.row];

        list[@"archived"] = @YES;

        [self.lists removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];

        [[SlabClient sharedClient] saveCollection:list block:^(NSDictionary *resp, NSError *error) {
            if (error != nil) {
                list[@"archived"] = @NO;
                [self.lists insertObject:list atIndex:indexPath.row];
                [self.tableView reloadData];
                NSLog(@"error archiving list: %@", error);
            }
            NSLog(@"rep from archive list: %@", resp);
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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
        
        NSMutableDictionary *listItem = [self.lists objectAtIndex:path.row];
        tvc.listItem = listItem;
    }
    
}


@end
