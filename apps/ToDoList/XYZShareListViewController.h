//
//  XYZShareListViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 11/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZShareListViewController : UIViewController


@property IBOutlet UITableView *tableView;

//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *dynamicTVHeight;


@property NSMutableArray* alreadyShared;

@property NSMutableDictionary *listItem;
@property NSMutableArray *todoItems;

@property NSString* publicKey;
@property NSString* phoneNumber;
@property NSString* emailAddress;
@property NSString* name;


@end
