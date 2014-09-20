//
//  XYZToDoListTableViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZToDoListTableViewController : UITableViewController

- (IBAction)unwindToList:(UIStoryboardSegue *)segue;
- (void) loadInitialData:(void (^)(NSError* error))callbackBlock;

@end
