//
//  XYZAddListViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/20/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZAddListViewController : UIViewController

@property NSMutableDictionary *listItem;
@property NSMutableDictionary *templateListItem;

- (IBAction)unwindToAddList:(UIStoryboardSegue *)segue;

@end
