//
//  XYZShareListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 10/5/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZShareListTableViewController.h"

#import "HMAccount.h"
#import "SLContactTableViewCell.h"

#import <APAddressBook.h>
#import <APContact.h>

@interface XYZShareListTableViewController ()

@end

@implementation XYZShareListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sections = [[NSMutableArray alloc] init];

    NSArray *grantIDs = [[((NSDictionary*)self.listItem[@"_grants"]) keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        NSString *keyString = (NSString*)key;
        return !([keyString containsString:@"-"] || [keyString isEqualToString:[[HMAccount currentAccount] getPublicKey]]);
    }] allObjects];
    [[HMAccount accountFromObject:self.listItem] getIdentities:grantIDs block:^(NSArray *alreadySharedWithIdentities, NSError *error) {

        NSArray *temporaryIDs = [[((NSDictionary*)self.listItem[@"_grants"]) keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            NSString *keyString = (NSString*)key;
            return [keyString containsString:@"-"];
        }] allObjects];
        [[HMAccount currentAccount] getTemporaryIdentities:temporaryIDs block:^(NSArray *temporaryIdentities, NSError *error) {
            self.alreadyShared = [NSMutableArray arrayWithArray:alreadySharedWithIdentities];
            [self.alreadyShared addObjectsFromArray:temporaryIdentities];
            NSLog(@"alreadySharedWithIdentities %@", alreadySharedWithIdentities);
    //        if (self.alreadyShared.count > 0) {
                [self.sections addObject:@"Sharing With"];
    //        }

            [[HMAccount currentAccount] getKnownIdentities:^(NSArray *identities, NSError *error) {
                self.identities = [[NSMutableArray alloc] init];
                for (NSDictionary *i in identities) {
                    if ([i[@"_id"] isEqualToString:[[HMAccount currentAccount] getPublicKey]]) continue;
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
                [addressBook loadContacts:^(NSArray *contacts, NSError *error) {
                    // hide activity
                    if (!error) {
                        self.contacts = [[NSMutableArray alloc] init];
                        for (APContact* contact in contacts) {
                            for (id phoneNumber in contact.phones) {
                                [self.contacts addObject:@{
                                                           @"name": contact.compositeName,
                                                           @"phone_number": phoneNumber
                                                           }];
                            }
                            for (id email in contact.emails) {
                                [self.contacts addObject:@{
                                                           @"name": contact.compositeName,
                                                           @"email": email
                                                           }];
                            }

                        }
                        NSLog(@"contacts %@", contacts);

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
    return 3;
//    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"id count: %lu, cont count: %lu", (unsigned long)[self.identities count], (unsigned long)[self.contacts count]);
    if (section == 0) return self.alreadyShared.count;
    if (section == 1) return self.identities.count;
    return self.contacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     SLContactTableViewCell *cell = (SLContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IdentityPrototypeCell" forIndexPath:indexPath];

    if (indexPath.section == 0) {
        cell.textLabel.text = self.alreadyShared[indexPath.row][@"name"];
        cell.detailTextLabel.text = self.alreadyShared[indexPath.row][@"_id"];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = self.identities[indexPath.row][@"name"];
        cell.detailTextLabel.text = self.identities[indexPath.row][@"_id"];
        cell.accessoryType = UITableViewCellAccessoryNone;
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
        cell.accessoryType = UITableViewCellAccessoryNone;
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
        else self.publicKey = cell.detailTextLabel.text;
    }

}


@end
