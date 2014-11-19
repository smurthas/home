//
//  XYZShareListViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 11/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZShareListViewController.h"
#import "XYZShareListTableViewController.h"

#import <SlabClient.h>
#import <SLAccount.h>


#import <MessageUI/MessageUI.h>

@interface XYZShareListViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end

@implementation XYZShareListViewController

- (void)viewDidLoad {
    self.title = [@"Share " stringByAppendingString:self.listItem[@"name"]];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self loadDataAndLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
    // just add this line to the end of this method or create it if it does not exist
    [self.tableView reloadData];
}

-(void)viewDidLayoutSubviews {
    CGFloat height = MAX(0, self.tableView.contentSize.height - 1);
    NSLog(@"height: %f", height);
    self.dynamicTVHeight.constant = height;

    [self.view layoutIfNeeded];
}


- (void) loadDataAndLayout {
    NSArray *grantIDs = [[((NSDictionary*)self.listItem[@"_grants"]) keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        NSString *keyString = (NSString*)key;
        return !([keyString containsString:@"-"]);
    }] allObjects];

    NSLog(@"getting grantIDs %@", grantIDs);

    // XXX: If grantIDs is nil or empty, the getIdentities method will return ALL known identities!
    [[SlabClient sharedClient] getIdentities:grantIDs block:^(NSArray *alreadySharedWithIdentities, NSError *error) {
        NSArray *temporaryIDs = [[((NSDictionary*)self.listItem[@"_grants"]) keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            NSString *keyString = (NSString*)key;
            return [keyString containsString:@"-"];
        }] allObjects];
        [[SlabClient sharedClient] getTemporaryIdentities:temporaryIDs block:^(NSArray *temporaryIdentities, NSError *error) {
            self.alreadyShared = [NSMutableArray arrayWithArray:alreadySharedWithIdentities];
            [self.alreadyShared addObjectsFromArray:temporaryIdentities];

            NSLog(@"alreadyShared %@", self.alreadyShared);
            [self.tableView reloadData];

            CGFloat height = MAX(0, self.tableView.contentSize.height - 1);
            NSLog(@"height: %f", height);
            self.dynamicTVHeight.constant = height;

            [self.view layoutIfNeeded];
        }];
    }];
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
    NSLog(@"self.alreadyShared.count: %lu", (unsigned long)self.alreadyShared.count);
    return self.alreadyShared.count + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == self.alreadyShared.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"InvitePeoplePrototypeCell" forIndexPath:indexPath];
        cell.textLabel.text = @"Invite People...";
        return cell;
    }


    cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];

    NSString *_id = self.alreadyShared[indexPath.row][@"_id"];
    if ([_id isEqualToString:[[SLAccount currentAccount] getPublicKey]]) {
        cell.textLabel.text = @"Me";
    } else {
        cell.textLabel.text = self.alreadyShared[indexPath.row][@"name"];
    }

    if ([_id containsString:@"-"]) {
        cell.detailTextLabel.text = @"Invite pending...";
    } else {
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

- (void)shareWith:(NSString*)grantID {
    [self shareWith:grantID accountID:nil baseUrl:nil];
}

- (void)shareWith:(NSString*)grantID accountID:(NSString *)accountID baseUrl:(NSString *)baseUrl {
    // enable the grantID to create objects in this collection
    self.listItem[@"_grants"][grantID] = [NSMutableDictionary dictionaryWithDictionary:@{
        @"createObjects": @YES,
        @"readAttributes": @YES,
        @"modifyAttributes": @YES
    }];

    [[SlabClient sharedClient] saveCollection:self.listItem block:^(NSDictionary *updateCollection, NSError *error) {
        // grant permission for all items in the list

        for (NSMutableDictionary* todo in self.todoItems) {
            ((NSMutableDictionary*)todo[@"_grants"])[grantID] =
            [NSMutableDictionary dictionaryWithDictionary:@{@"read": @YES, @"write": @YES}];
        }

        [[SlabClient sharedClient] batchUpdate:self.todoItems toCollection:self.listItem block:^(NSDictionary *responseObject, NSError *error) {
            NSLog(@"JSON: %@", responseObject);

            [self loadDataAndLayout];
            // TODO: update the _updatedAt timestamps

            if (accountID != nil && baseUrl != nil) {

                NSMutableDictionary *remoteCollection = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"_host": baseUrl,
                    @"_accountID": accountID,
                    @"_id": @"_pendingSharedLists"
                }];

                NSMutableDictionary *shareGrants =[NSMutableDictionary dictionaryWithDictionary:@{
                    grantID:[NSMutableDictionary dictionaryWithDictionary:@{
                        @"read": @YES,
                        @"write": @YES,
                    }],
                    [[SLAccount currentAccount] getPublicKey]: [NSMutableDictionary dictionaryWithDictionary:@{
                          @"read": @YES,
                          @"write": @YES,
                    }]
                }];
                NSMutableDictionary *shareNotification = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"_grants": shareGrants,
                    @"collection": @{
                        @"_host": self.listItem[@"_host"],
                        @"_accountID": self.listItem[@"_accountID"],
                        @"_id": self.listItem[@"_id"],
                        @"name": self.listItem[@"name"],
                        @"type": @"list"
                    }
                }];

                [[SlabClient sharedClient] saveInBackground:shareNotification toCollection:remoteCollection];
            } else {
                // never shared with them before, so give the temp grant permission to write to _pendingSharedLists
                SLQuery * pendingSharedListQuery = [SLQuery collectionQuery];
                [pendingSharedListQuery whereKey:@"_id" equalTo:@"_pendingSharedLists"];
                [[SlabClient sharedClient] findInBackground:pendingSharedListQuery account:[SLAccount currentAccount] block:^(NSArray *objects, NSError *error) {
                    NSLog(@"pending shared query response: %@", objects);
                    NSMutableDictionary *pendingSharedListAttributes;
                    if (objects != nil && objects.count > 0) {
                        pendingSharedListAttributes = [NSMutableDictionary dictionaryWithDictionary:objects[0]];
                    } else {
                        pendingSharedListAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
                            @"_id": @"_pendingSharedLists",
                            @"_grants": [NSMutableDictionary dictionaryWithDictionary:@{
                                [[SLAccount currentAccount] getPublicKey]: @{
                                    @"createObjects": @YES,
                                    @"modifyAttributes": @YES,
                                    @"readAttributes": @YES
                                }
                            }],
                            @"_host": [[SLAccount currentAccount] getBaseUrl],
                            @"_accountID": [[SLAccount currentAccount] getAccountID]
                        }];
                    }
                    pendingSharedListAttributes[@"_grants"][grantID] = [NSMutableDictionary dictionaryWithDictionary:@{
                        @"createObjects": @YES
                    }];

                    NSLog(@"pendingSharedListAttributes %@", pendingSharedListAttributes);

                    [[SlabClient sharedClient] saveCollection:pendingSharedListAttributes block:^(NSDictionary *response, NSError *saveError) {
                        NSLog(@"savePendingCollection resp, err %@, %@", response, saveError);
                    }];
                }];
            }
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

- (IBAction)unwindToShareList:(UIStoryboardSegue *)segue {
    XYZShareListTableViewController *source = [segue sourceViewController];
    NSLog(@"sharing list %@, public key %@", self.listItem[@"name"], source.publicKey);

    if (source.publicKey != nil) {
        NSLog(@"sharing with pubkey");
        [self shareWith:source.publicKey accountID:source.accountID baseUrl:source.baseUrl];

        // TODO: send notification without token

    } else if (source.emailAddress != nil || source.phoneNumber != nil) {
        NSLog(@"creating identity");
        // create an identity with an alias and a token
        NSMutableDictionary *identityParameters = [[NSMutableDictionary alloc] init];
        if (source.name != nil) identityParameters[@"name"] = source.name;
        if (source.emailAddress != nil) identityParameters[@"email"] = source.emailAddress;
        if (source.phoneNumber != nil) identityParameters[@"phone_number"] = source.phoneNumber;

        NSLog(@"identityParameters %@", identityParameters);

        [[SlabClient sharedClient] createTemporaryIdentity:identityParameters account:[SLAccount accountFromObject:self.listItem] block:^(NSString *token, NSError *error) {
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
            NSLog(@"share url %@", url);

            NSString *body = [NSString stringWithFormat:@"Help me keep track of all these todos!\n\n Join \"%@\": %@", self.listItem[@"name"], url];

            if (source.emailAddress != nil) {
                NSLog(@"emailing: %@", source.emailAddress);
                //Check if mail can be sent
                if ([MFMailComposeViewController canSendMail])
                {
                    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                    mailer.mailComposeDelegate = self;
                    NSLog(@"emailadress %@", source.emailAddress);

                    [mailer setToRecipients:@[source.emailAddress]];
                    [mailer setSubject:[NSString stringWithFormat:@"Collaborate on \"%@\" with me", self.listItem[@"name"]]];
                    [mailer setMessageBody:body isHTML:NO];

                    [self presentViewController:mailer animated:YES completion:nil];

                } else {
                    NSLog(@"can't sent mail!");
                }
            } else if (source.phoneNumber != nil) {
                if(![MFMessageComposeViewController canSendText]) {
                    UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [warningAlert show];
                    return;
                }
            
                MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
                messageController.messageComposeDelegate = self;
                [messageController setRecipients:@[source.phoneNumber]];
                [messageController setBody:body];
            
                // Present message view controller on screen
                [self presentViewController:messageController animated:YES completion:nil];
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

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"It's dismissed!");
    }];
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    if (result == MessageComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"It's dismissed!");
    }];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.row == self.alreadyShared.count) {
        [self performSegueWithIdentifier:@"DoShare" sender:cell];
    } else {
        // TODO: show details
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.row < self.alreadyShared.count;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source

        NSString *_id = self.alreadyShared[indexPath.row][@"_id"];
        NSLog(@"_id: %@", _id);
        [self.listItem[@"_grants"] removeObjectForKey:_id];

        // update collection object
        [[SlabClient sharedClient] saveCollection:self.listItem block:^(NSDictionary *reponse, NSError *error) {
            // update all other objects
            for (NSMutableDictionary *item in self.todoItems) {
                [item[@"_grants"] removeObjectForKey:_id];
            }

            [[SlabClient sharedClient] batchUpdate:self.todoItems toCollection:self.listItem block:^(NSDictionary *bResp, NSError *bErr) {
                // remove from UI
                [self.alreadyShared removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadData];
            }];
        }];

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
