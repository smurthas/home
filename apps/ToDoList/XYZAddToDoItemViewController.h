//
//  XYZAddToDoItemViewController.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYZAddToDoItemViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property NSMutableDictionary *toDoItem;
@property NSMutableDictionary *listItem;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)addPhoto:(id)sender;
- (IBAction)quickAddButton:(id)sender;

@end
