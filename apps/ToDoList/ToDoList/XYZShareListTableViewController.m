//
//  XYZShareListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 10/5/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZShareListTableViewController.h"

#import <SlabClient/SLAccount.h>
#import <SlabClient/SlabClient.h>
#import "SLContactTableViewCell.h"

#import <APAddressBook.h>
#import <APContact.h>

@interface XYZShareListTableViewController ()

@end

@implementation XYZShareListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sections = [[NSMutableArray alloc] init];

    // XXX: If grantIDs is nil or empty, the getIdentities method will return ALL known identities!
    [[SlabClient sharedClient] getKnownIdentities:^(NSArray *knownIdentities, NSError *error) {
        NSLog(@"knownIdentities %@", knownIdentities);
        self.identities = [[NSMutableArray alloc] init];
        NSString *myPublicKey = [[SLAccount currentAccount] getPublicKey];
        for (NSDictionary *i in knownIdentities) {
            if ([i[@"_id"] isEqualToString:myPublicKey]) continue;
            BOOL found = NO;
            for (NSDictionary *j in self.alreadyShared) {
                NSLog(@"i._id:%@, j._id:%@", i[@"_id"], j[@"_id"]);
                if ([j[@"_id"] isEqualToString:i[@"_id"]]) {
                    found = YES;
                    break;
                }
            }
            if (!found) {
                [self.identities addObject:i];
            }
        }

//            if (self.identities.count > 0) {
            [self.sections addObject:@"Known Identities"];
//            }

        // TODO: get contacts from address book
        APAddressBook *addressBook = [[APAddressBook alloc] init];
        addressBook.fieldsMask = APContactFieldFirstName |
            APContactFieldEmails |
            APContactFieldLastName |
            APContactFieldPhones |
            APContactFieldCompositeName;
        NSLog(@"loading contacts...");
        [addressBook loadContacts:^(NSArray *contacts, NSError *error) {
            NSLog(@"loaded contacts!");
            // hide activity
            if (!error) {
                self.contacts = [[NSMutableArray alloc] init];
                for (APContact* contact in contacts) {
                    NSString *name = contact.compositeName;
                    if (name == nil) name = @"";
                    for (id phoneNumber in contact.phones) {
                        if (phoneNumber == nil) continue;
                        [self.contacts addObject:@{
                                                   @"name": name,
                                                   @"phone_number": phoneNumber
                                                   }];
                    }
                    for (id email in contact.emails) {
                        if (email == nil) continue;
                        [self.contacts addObject:@{
                                                   @"name": name,
                                                   @"email": email
                                                   }];
                    }

                }

                [self.contacts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSString *name1 = obj1[@"name"];
                    NSString *name2 = obj2[@"name"];
                    return [name1 compare:name2 options:NSCaseInsensitiveSearch];
                }];
//                NSLog(@"contacts %@", contacts);

//                    if (self.contacts.count > 0) {
                    [self.sections addObject:@"Contact List"];
//                   }

                [self.tableView reloadData];
                // do something with contacts array
            } else {
                // show error
            }

        }];
    }];

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
    return 2;
//    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"id count: %lu, cont count: %lu", (unsigned long)[self.identities count], (unsigned long)[self.contacts count]);
    if (section == 0) return self.identities.count;
    return self.contacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     SLContactTableViewCell *cell = (SLContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IdentityPrototypeCell" forIndexPath:indexPath];
//
//    if (indexPath.section == 0) {
//        NSString *_id = self.alreadyShared[indexPath.row][@"_id"];
//        if ([_id isEqualToString:[[HMAccount currentAccount] getPublicKey]]) {
//            cell.textLabel.text = @"Me";
//        } else {
//            cell.textLabel.text = self.alreadyShared[indexPath.row][@"name"];
//        }
//
//        if ([_id containsString:@"-"]) {
//            cell.detailTextLabel.text = @"Invite pending...";
//        } else {
//            cell.detailTextLabel.text = nil;
//        }
////        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//    } else
    if (indexPath.section == 0) {
        NSDictionary *idty = self.identities[indexPath.row];
        NSLog(@"idty %@", idty);
        cell.textLabel.text = idty[@"name"];
        cell.detailTextLabel.text = idty[@"_id"];
        if (idty[@"_accountID"] != nil) cell.accountID = idty[@"_accountID"];
        if (idty[@"_baseUrl"] != nil) cell.baseUrl = idty[@"_baseUrl"];
        if (idty[@"_appData"][@"myTodos"][@"deviceToken"] != nil) cell.deviceToken = idty[@"_appData"][@"myTodos"][@"deviceToken"];
//        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSDictionary *contact = (NSDictionary*)self.contacts[indexPath.row];

        cell.isEmail = NO;
        cell.isPhoneNumber = NO;

        cell.textLabel.text = contact[@"name"];
        if (contact[@"email"] != nil) {
            cell.detailTextLabel.text = contact[@"email"];
            cell.isEmail = YES;
        } else if (contact[@"phone_number"] != nil) {
            cell.detailTextLabel.text = contact[@"phone_number"];
            cell.isPhoneNumber = YES;
        }
//        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    /*
    
    // Configure the cell...
    if (indexPath.section == 0 && [self.identities count] > 0) {
        cell.textLabel.text =self.identities[indexPath.row][@"name"];
        cell.detailTextLabel.text = self.identities[indexPath.row][@"_id"];
    } else {
        NSDictionary *contact = (NSDictionary*)self.contacts[indexPath.row];
        cell.textLabel.text = contact[@"name"];
        if (contact[@"email"] != nil) {
            cell.detailTextLabel.text = contact[@"email"];
            cell.isEmail = YES;
        } else if (contact[@"phone_number"] != nil) {
            cell.detailTextLabel.text = contact[@"phone_number"];
            cell.isPhoneNumber = YES;
        }
    }*/


    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sections.count > section? self.sections[section]: nil;
    /*
    int sections = (self.identities.count > 0) + (self.contacts.count > 0) + (self.alreadyShared.count > 0);

    if (sections == 3) {

    }
    if (section == 0 && self.identities.count > 0) return @"Known Identities";
    return @"Contacts";*/
}



/*// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.section == 0;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source

        HMAccount *listAccount = [HMAccount accountFromObject:self.listItem];
        NSString *_id = self.alreadyShared[indexPath.row][@"_id"];
        NSLog(@"_id: %@", _id);
        [self.listItem[@"_grants"] removeObjectForKey:_id];

        // update collection object
        [listAccount saveCollection:self.listItem block:^(NSDictionary *reponse, NSError *error) {
            // update all other objects
            for (NSMutableDictionary *item in self.todoItems) {
                [item[@"_grants"] removeObjectForKey:_id];
            }

            [listAccount batchUpdate:self.todoItems toCollection:self.listItem[@"_id"] block:^(NSDictionary *bResp, NSError *bErr) {
                // remove from UI
                [self.alreadyShared removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadData];
            }];
        }];

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}*/



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




#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//
//    if (indexPath.section == 0) {
//        // a known identity
//        self.accountID = self.identities[indexPath.row]
//        self.baseUrl = cell.baseUrl;
//
//    }
    // TODO: can this just be a regular unwind segue?
    [self performSegueWithIdentifier:@"Unwind" sender:cell];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//    self.publicKey = ((UITableViewCell *)sender).detailTextLabel.text;
    if ([sender class] == [SLContactTableViewCell class]) {
        SLContactTableViewCell *cell = (SLContactTableViewCell *)sender;
        self.name = cell.textLabel.text;
        if (cell.isEmail) self.emailAddress = cell.detailTextLabel.text;
        else if (cell.isPhoneNumber) self.phoneNumber = cell.detailTextLabel.text;
        else {
            self.publicKey = cell.detailTextLabel.text;
            self.accountID = cell.accountID;
            self.baseUrl = cell.baseUrl;
            self.deviceToken = cell.deviceToken;
        }
    }
}


@end
