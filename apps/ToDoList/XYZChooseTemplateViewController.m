//
//  XYZChooseTemplateViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 12/3/16.
//  Copyright © 2016 Simon Murtha Smith. All rights reserved.
//

#import "XYZChooseTemplateViewController.h"
#import "XYZAddListViewController.h"

#import <SlabClient/SlabClient.h>
#import <SlabClient/SLAccount.h>
#import <SlabClient/SLQuery.h>

@interface XYZChooseTemplateViewController ()

@property NSArray *lists;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

@implementation XYZChooseTemplateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadLists];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.lists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListListPrototypeCell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self.lists objectAtIndex:indexPath.row][@"name"];
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void) loadLists {
    SLQuery *query = [SLQuery collectionQuery];
    [query whereKey:@"type" equalTo:@"list"];
//    [query whereKey:@"archived" equalTo:@{@"$ne":@YES}];
    
    [[SlabClient sharedClient] findInBackground:query account:[SLAccount currentAccount] block:^(NSMutableArray *objects, NSError *error) {
        if (error != nil) return;// callbackBlock(error);
        
        //        NSLog(@"filling with objects: %@", objects);
        
        self.lists = objects;
        [self.tableView reloadData];
//        callbackBlock(nil);
    }];
    
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if (sender == self.cancelButton) return;
    
    NSLog(@"preparing for segue");
    
//    if ([[segue destinationViewController] class] == [XYZToDoListTableViewController class]) {
        XYZAddListViewController *alvc = (XYZAddListViewController*)[segue destinationViewController];
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        
        NSMutableDictionary *templateListItem = [self.lists objectAtIndex:path.row];
        alvc.templateListItem = templateListItem;
//    }

    /*
    if (self.textField.text.length > 0) {
        self.listItem = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                        @"name": self.textField.text,
                                                                        @"type": @"list",
                                                                        @"_grants": [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                                    [[SLAccount currentAccount] getPublicKey]: @{
                                                                                                                                            @"createObjects": @YES,
                                                                                                                                            @"readAttributes": @YES,
                                                                                                                                            @"modifyAttributes": @YES
                                                                                                                                            }
                                                                                                                                    }]
                                                                        }];
    }
    
    NSLog(@"listItem: %@", self.listItem);
    // XXX: this is a race condition as the collection will be added before it has a
    // chance to be created on the backend. As a result, the object won't have the
    // required _host, etc fields so `accountFromObject` won't work.
    // TODO: real solution is offline/not logged in editing
    [[SlabClient sharedClient] createCollectionWithAttributes:self.listItem block:^(NSDictionary *collection, NSError *error) {
        for (NSString *key in [collection allKeys]) {
            self.listItem[key] = collection[key];
        }
        
        NSLog(@"collection: %@", collection);
    }];*/
}




@end
