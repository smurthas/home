//
//  XYZToDoListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HMAccount.h"

@interface XYZToDoListTableViewController : UITableViewController

@property NSMutableArray *toDoItems;
@property NSMutableDictionary *listItem;
@property HMAccount *account;

- (IBAction)unwindToShareList:(UIStoryboardSegue *)segue;
- (IBAction)logCompleted:(id)sender;
//- (IBAction)logCompleted:(UIStoryboardSegue *)segue;

- (void) loadInitialData:(void (^)(NSError* error))callbackBlock;

@end
