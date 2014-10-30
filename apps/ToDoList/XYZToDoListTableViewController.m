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

#import "HMQuery.h"
#import "HMAccount.h"

#import <AFNetworking.h>

#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface XYZToDoListTableViewController ()

//@property NSArray* identities;

@end

@implementation XYZToDoListTableViewController


- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    HMQuery *query = [HMQuery objectQueryWithCollectionName:self.listItem[@"_id"]];
    [query whereKey:@"logged" equalTo:@NO];

    [[HMAccount accountFromObject:self.listItem] findInBackground:query block:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            self.toDoItems = [NSMutableArray arrayWithArray:objects];
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

    [[HMAccount accountFromObject:self.listItem] batchUpdate:toLog toCollection:self.listItem[@"_id"] block:^(NSDictionary *response, NSError *error) {
        for (NSDictionary *todo in toLog) {
            [self.toDoItems removeObject:todo];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddToDoItemViewController *source = [segue sourceViewController];

    if (source.toDoItem != nil) {
        source.toDoItem[@"_grants"] = [[NSMutableDictionary alloc] init];
        source.toDoItem[@"_grants"][[self.account getPublicKey]] = [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];

        for (id grantID in self.listItem[@"_grants"]) {
            source.toDoItem[@"_grants"][grantID] = [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];
        }

        [[HMAccount accountFromObject:self.listItem] saveInBackground:source.toDoItem toCollection:self.listItem[@"_id"]];
        [self.toDoItems insertObject:source.toDoItem atIndex:0];
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

- (void)shareWith:(NSString*)grantID {
    // enable the grantID to create objects in this collection
    self.listItem[@"_grants"][grantID] = [NSMutableDictionary dictionaryWithDictionary:@{
         @"createObjects": @YES,
         @"readAttributes": @YES,
         @"modifyAttributes": @YES
    }];

    HMAccount *listAccount = [HMAccount accountFromObject:self.listItem];
    [listAccount saveCollection:self.listItem block:^(NSDictionary *updateCollection, NSError *error) {
        // grant permission for all items in the list

        for (NSMutableDictionary* todo in self.toDoItems) {
            ((NSMutableDictionary*)todo[@"_grants"])[grantID] =
                [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];
        }

        [listAccount batchUpdate:self.toDoItems toCollection:self.listItem[@"_id"] block:^(NSDictionary *responseObject, NSError *error) {
            NSLog(@"JSON: %@", responseObject);

            // TODO: update the _updatedAt timestamps

            // send the other account a notification with my AccountID, List Name, CollectionID
            // TODO: send it

            //            [self.account createGrantWithPublicKey:toPublicKey block:^(NSDictionary *grant, NSError *error) {
            //                NSString *resourceURL = [self.account URLStringForCollection:self.listItem[@"_id"]];
            //                NSLog(@"sharing resourceURL: %@", resourceURL);
            //
            //                               NSDictionary *invitation = @{
            //                 @"token": grant[@"token"],
            //                 @"uri": resourceURL
            //                 };
            //
            //                 NSLog(@"sharing: %@", invitation);
            //            }];
            
        }];
        
    }];
}

- (IBAction)unwindToShareList:(UIStoryboardSegue *)segue
{
    XYZShareListTableViewController *source = [segue sourceViewController];
    NSLog(@"sharing list %@, public key %@", self.listItem[@"name"], source.publicKey);

    if (source.publicKey != nil) {
        NSLog(@"sharing with pubkey");
        [self shareWith:source.publicKey];

        // TODO: send notification without token

    } else if (source.emailAddress != nil || source.phoneNumber != nil) {
        NSLog(@"creating identity");
        // create an identity with an alias and a token
        NSMutableDictionary *identityParameters = [[NSMutableDictionary alloc] init];
        if (source.name != nil) identityParameters[@"name"] = source.name;
        if (source.emailAddress != nil) identityParameters[@"email"] = source.emailAddress;
        if (source.phoneNumber != nil) identityParameters[@"phone_number"] = source.phoneNumber;
        
        [[HMAccount accountFromObject:self.listItem] createTemporaryIdentity:identityParameters block:^(NSString *token, NSError *error) {
            NSLog(@"token %@", token);
            [self shareWith:token];

            // send email/text
            NSMutableDictionary *messagePayload = [[NSMutableDictionary alloc] init];
            messagePayload[@"token"] = token;
            messagePayload[@"base_url"] = self.listItem[@"_host"];
            messagePayload[@"account_id"] = self.listItem[@"_accountID"];
            messagePayload[@"collection_id"] = self.listItem[@"_id"];
            messagePayload[@"list_name"] = self.listItem[@"name"];

            NSString *url = [NSString stringWithFormat:@"todos://com.sms.todos/accept_invite?token=%@&base_url=%@&account_id=%@&collection_id=%@&list_name=%@",
                  messagePayload[@"token"],
                  [messagePayload[@"base_url"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                  messagePayload[@"account_id"],
                  messagePayload[@"collection_id"],
                  messagePayload[@"list_name"]];

            if (source.emailAddress != nil) {
                //Check if mail can be sent
                if ([MFMailComposeViewController canSendMail])
                {
                    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                    mailer.mailComposeDelegate = self;
                    NSLog(@"emailadress %@", source.emailAddress);
//                    [mailer setToRecipients:@[source.emailAddress]];
//                    [mailer setMessageBody:url isHTML:NO];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

                        [self presentViewController:mailer
                                           animated:YES completion:^{
                                               NSLog(@"ok");
                                           }];
                    });
                    
                } else {
                    NSLog(@"can't sent mail!");
                }
            } else if (source.phoneNumber != nil) {

            }

            /*
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                              applicationActivities:nil];
            [self presentViewController:activityViewController
                               animated:YES
                             completion:^{
                NSLog(@"shared!");
            }];*/
        }];
    }
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
        if ([vc isKindOfClass:[XYZShareListTableViewController class]]) {
            XYZShareListTableViewController *sltvc = (XYZShareListTableViewController*)vc;
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
    
    NSString *collectionID = self.listItem[@"_id"];
    
    [[HMAccount accountFromObject:self.listItem] deleteInBackground:toDoItem fromCollection:collectionID];
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
    
    NSString *collectionID = self.listItem[@"_id"];
    [[HMAccount accountFromObject:self.listItem] saveInBackground:tappedItem toCollection:collectionID];
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
