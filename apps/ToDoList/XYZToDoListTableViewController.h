//
//  XYZToDoListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface XYZToDoListTableViewController : UITableViewController

@property NSMutableArray *toDoItems;
@property NSMutableDictionary *listItem;

- (IBAction)logCompleted:(id)sender;
- (IBAction)startEditing:(id)sender;

- (void) loadInitialData:(void (^)(NSError* error))callbackBlock;

- (IBAction)toggleCompleted:(id)sender;

@end
