//
//  XYZListsListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/20/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZListsListTableViewController : UITableViewController

- (IBAction)unwindToList:(UIStoryboardSegue *)segue;
- (void) loadInitialData:(void (^)(NSError* error))callbackBlock;

@end
