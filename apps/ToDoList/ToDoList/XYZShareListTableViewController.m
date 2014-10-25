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

    [[HMAccount currentAccount] getKnownIdentities:^(NSArray *identities, NSError *error) {
        self.identities = identities;

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
    if ([self.identities count] > 0 && [self.contacts count] > 0) return 2;
    if ([self.identities count] > 0 || [self.contacts count] > 0) return 1;
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"id count: %lu, cont count: %lu", (unsigned long)[self.identities count], (unsigned long)[self.contacts count]);
    if (section == 0 && [self.identities count] > 0) return [self.identities count];
    return [self.contacts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     SLContactTableViewCell *cell = (SLContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IdentityPrototypeCell" forIndexPath:indexPath];
    
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
    }


    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && self.identities.count > 0) return @"Identities";
    return @"Contacts";
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
    }

}


@end
