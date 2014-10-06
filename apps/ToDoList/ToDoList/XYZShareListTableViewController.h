//
//  XYZShareListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 10/5/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZShareListTableViewController : UITableViewController

@property NSArray* identities;
@property NSString* publicKey;
@property NSString* phoneNumber;
@property NSString* emailAddress;
@property NSString* name;

@end
