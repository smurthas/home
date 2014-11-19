//
//  XYZShareListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 10/5/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZShareListTableViewController : UITableViewController

@property NSMutableArray* identities;
@property NSMutableArray* contacts;
@property NSMutableArray* alreadyShared;

@property NSMutableArray* sections;

@property NSMutableDictionary *listItem;
@property NSMutableArray *todoItems;

@property NSString* publicKey;
@property NSString* accountID;
@property NSString* baseUrl;

@property NSString* phoneNumber;
@property NSString* emailAddress;
@property NSString* name;


@end
