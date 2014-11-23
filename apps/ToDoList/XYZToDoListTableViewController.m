//
//  XYZToDoListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZToDoListTableViewController.h"
#import "XYZAddToDoItemViewController.h"
#import "XYZShareListTableViewController.h"
#import "XYZShareListViewController.h"


#import <SlabClient/SLCrypto.h>
#import <SlabClient/SLAccount.h>
#import <SlabClient/SLQuery.h>
#import <SlabClient/SlabClient.h>


#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface XYZToDoListTableViewController ()

//@property NSArray* identities;

@end

@implementation XYZToDoListTableViewController


- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    SLQuery *query = [SLQuery objectQueryWithCollectionName:self.listItem[@"_id"]];
    [query whereKey:@"logged" equalTo:@NO];

    [[SlabClient sharedClient] findInBackground:query account:[SLAccount accountFromObject:self.listItem] block:^(NSArray *objects, NSError *error) {
        NSLog(@"got back objects for collection: %@", objects);
        if (error == nil) {
            self.toDoItems = [NSMutableArray arrayWithArray:objects];
            [self.toDoItems sortUsingComparator:^NSComparisonResult(NSMutableDictionary *obj1, NSMutableDictionary *obj2) {
                if (obj1[@"sortOrder"] == nil) {
                    obj1[@"sortOrder"] = @1073741824.0;
                }
                if (obj2[@"sortOrder"] == nil) {
                    obj2[@"sortOrder"] = @1073741824.0;
                }

                double one = [obj1[@"sortOrder"] doubleValue];
                double two = [obj2[@"sortOrder"] doubleValue];

                if (one < two) return NSOrderedAscending;
                else if (one > two) return NSOrderedDescending;
                return NSOrderedSame;
            }];

            NSLog(@"sorted collection: %@", self.toDoItems);

            [self.tableView reloadData];
            callbackBlock(nil);
        }
        callbackBlock(error);
    }];
}

- (IBAction)logCompleted:(id)sender {
    NSMutableArray *toLog = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *todo in self.toDoItems) {
        if ([todo[@"completed"] isEqual:@YES]) {
            todo[@"logged"] = @YES;
            [toLog addObject:todo];
        }
    }

    NSLog(@"toLog %@", toLog);

    [[SlabClient sharedClient] batchUpdate:toLog toCollection:self.listItem block:^(NSDictionary *response, NSError *error) {
        for (NSDictionary *todo in toLog) {
            [self.toDoItems removeObject:todo];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)startEditing:(id)sender {
    if (self.editing == YES) {
        ((UIBarButtonItem*)sender).title = @"Edit";
        self.editing = NO;
    } else {
        ((UIBarButtonItem*)sender).title = @"Done";
        self.editing = YES;
    }
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
    XYZAddToDoItemViewController *source = [segue sourceViewController];

    if (source.toDoItem != nil) {
        source.toDoItem[@"_grants"] = [[NSMutableDictionary alloc] init];
        source.toDoItem[@"_grants"][[[SLAccount currentAccount] getPublicKey]] = [NSMutableDictionary dictionaryWithDictionary:@{
                @"read": @YES,
                @"write": @YES
            }];

        for (id grantID in self.listItem[@"_grants"]) {
            source.toDoItem[@"_grants"][grantID] = [NSMutableDictionary dictionaryWithDictionary:@{
                @"read": @YES,
                @"write": @YES
            }];
        }

        double min = 1073741824.0;
        for (NSDictionary *todoItem in self.toDoItems) {
            if ([todoItem[@"sortOrder"] doubleValue] < min) {
                min = [todoItem[@"sortOrder"] doubleValue];
            }
        }

        source.toDoItem[@"sortOrder"] = [NSNumber numberWithDouble:(min / 2.0)];

        [[SlabClient sharedClient] saveInBackground:source.toDoItem toCollection:self.listItem];
        [self.toDoItems insertObject:source.toDoItem atIndex:0];
        [self.tableView reloadData];
    }
}

- (IBAction)unwindFromSharing:(UIStoryboardSegue *)segue {

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
    self.title = self.listItem[@"name"];

    [self loadInitialData:^(NSError *error) {
        NSLog(@"reloaded data");
    }];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{

    // dismiss the compose message view controller
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissed");
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
    NSLog(@"title %@", toDoItem[@"title"]);
    if (toDoItem[@"image"] != nil) {
        NSData *imageData = [SLCrypto dataFromStringWithHex:toDoItem[@"image"]];
        [cell.imageView setImage:[UIImage imageWithData:imageData]];
    } else {
        [cell.imageView setImage:nil];
    }

    cell.textLabel.text = toDoItem[@"title"];

    cell.layoutMargins = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
    
    if ([toDoItem[@"completed"] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];

        // set the tint color so that the check mark will show up gray
        [cell setTintColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1]];

        // create the inset look gradient for the top
        CAGradientLayer *topGradient = [CAGradientLayer layer];
        topGradient.frame = cell.bounds;
        topGradient.frame = CGRectMake(0, 0, 320, 1.5);
        topGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1] CGColor], (id)[[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1] CGColor], nil];
        [cell.layer insertSublayer:topGradient atIndex:0];

        // create the inset look gradient for the bottom
        CAGradientLayer *bottomGradient = [CAGradientLayer layer];
        bottomGradient.frame = cell.bounds;
        bottomGradient.frame = CGRectMake(0, 43, 320, 1);
        bottomGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1] CGColor], (id)[[UIColor colorWithRed:0.84 green:0.84 blue:0.84 alpha:1] CGColor], nil];
        [cell.layer insertSublayer:bottomGradient atIndex:0];

        // backrgound of the label must be transparent to be able to see the gradient underneath
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor grayColor];
    } else {
        [cell setBackgroundColor:[UIColor whiteColor]];
         cell.textLabel.textColor = [UIColor blackColor];
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


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSLog(@"sorting start %@", self.toDoItems);
    NSMutableDictionary *todoItem = self.toDoItems[fromIndexPath.row];

    [self.toDoItems removeObjectAtIndex:fromIndexPath.row];
    const double MIN = -2147483648.0;
    const double MAX = 2147483648.0;
    double before = MIN;
    double after = MAX;
    if (toIndexPath.row == 0) {
        after = [self.toDoItems[toIndexPath.row][@"sortOrder"] doubleValue];
    } else if (toIndexPath.row == self.toDoItems.count) {
        before = [self.toDoItems[toIndexPath.row - 1][@"sortOrder"] doubleValue];
    } else {
        after = [self.toDoItems[toIndexPath.row][@"sortOrder"] doubleValue];
        before = [self.toDoItems[toIndexPath.row - 1][@"sortOrder"] doubleValue];
    }

    [self.toDoItems insertObject:todoItem atIndex:toIndexPath.row];

    if (after - before < 1.0) {
        //time to rebalance
        double spacing = (MAX - MIN) / ((double)self.toDoItems.count + 1.0);
        double current = MIN + spacing;
        for (NSMutableDictionary *item in self.toDoItems) {
            item[@"sortOrder"] = [NSNumber numberWithDouble:current];
            current += spacing;
        }

        NSLog(@"rebalancing complete %@", self.toDoItems);

        [[SlabClient sharedClient] batchUpdate:self.toDoItems toCollection:self.listItem block:^(NSDictionary *resp, NSError *error) {
            NSLog(@"batch update complete!");
        }];
    } else {
        // still some space, just put it in the middle
        double sortOrder = (before + after) / 2.0;
        todoItem[@"sortOrder"] = [NSNumber numberWithDouble:sortOrder];
        NSLog(@"sorting end %@", self.toDoItems);
        [[SlabClient sharedClient] saveInBackground:todoItem toCollection:self.listItem];
    }
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UIViewController *vc = [segue destinationViewController];
    NSLog(@"vc %@", vc);
    if ([vc isKindOfClass:[UINavigationController class]]) {
        vc = [((UINavigationController*)vc) visibleViewController];
        NSLog(@"vc2 %@", vc);
        if ([vc isKindOfClass:[XYZShareListViewController class]]) {
            XYZShareListViewController *sltvc = (XYZShareListViewController*)vc;
            sltvc.listItem = self.listItem;
            sltvc.todoItems = self.toDoItems;
        }

    }
}


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
    
    
    [[SlabClient sharedClient] deleteInBackground:toDoItem fromCollection:self.listItem];
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableDictionary *tappedItem = [self.toDoItems objectAtIndex:indexPath.row];
    if ([tappedItem[@"completed"]  isEqual: @YES]) {
        tappedItem[@"completed"] = @NO;
    } else {
        tappedItem[@"completed"] = @YES;
    }

    [[SlabClient sharedClient] saveInBackground:tappedItem toCollection:self.listItem];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
