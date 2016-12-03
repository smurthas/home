//
//  XYZAddListViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/20/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZAddListViewController.h"

#import <SlabClient/SLAccount.h>
#import <SlabClient/SlabClient.h>

@interface XYZAddListViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *templateNameLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

@implementation XYZAddListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.textField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if (sender == self.cancelButton) return;
    if (sender != self.doneButton) return;
    
    if (self.textField.text.length > 0) {
        self.listItem = [NSMutableDictionary dictionaryWithDictionary:@{
            @"name": self.textField.text,
            @"type": @"list",
            @"_grants": [NSMutableDictionary dictionaryWithDictionary:@{
                [[SLAccount currentAccount] getPublicKey]: @{
                    @"createObjects": @YES,
                    @"readAttributes": @YES,
                    @"modifyAttributes": @YES
                }
            }]
        }];
    }
    
    NSLog(@"listItem: %@", self.listItem);
    // XXX: this is a race condition as the collection will be added before it has a
    // chance to be created on the backend. As a result, the object won't have the
    // required _host, etc fields so `accountFromObject` won't work.
    // TODO: real solution is offline/not logged in editing
    [[SlabClient sharedClient] createCollectionWithAttributes:self.listItem block:^(NSDictionary *collection, NSError *error) {
        for (NSString *key in [collection allKeys]) {
            self.listItem[key] = collection[key];
        }
        
        if (self.templateListItem != nil) {
            [self loadTodosFromList:^(NSArray *objects, NSError *error) {
                for (NSDictionary* immutableTodoItem in objects) {
                    NSMutableDictionary *todoItem = [immutableTodoItem mutableCopy];
                    todoItem[@"completed"] = @NO;
                    todoItem[@"logged"] = @NO;
                    todoItem[@"snoozed"] = @NO;
                    [[SlabClient sharedClient] saveInBackground:todoItem toCollection:self.listItem];
                }
            }];
        }
        
        NSLog(@"collection: %@", collection);
    }];
}


- (IBAction)unwindToAddList:(UIStoryboardSegue *)segue
{
    NSLog(@"did unwind to add list view, %@", self.templateListItem);
    self.templateNameLabel.text = self.templateListItem[@"name"];
//    XYZAddListViewController *source = [segue sourceViewController];
//    NSLog(@"listItem: %@", source.listItem);
//    if (source.listItem != nil) {
//        [self.lists insertObject:source.listItem atIndex:0];
//        [self.tableView reloadData];
//    }
}


- (void) loadTodosFromList:(void (^)(NSArray *objects,NSError* error))callbackBlock {
    SLQuery *query = [SLQuery objectQueryWithCollectionName:self.templateListItem[@"_id"]];
    NSLog(@"loading initial data from templateListItem %@", self.templateListItem);
    
    [[SlabClient sharedClient] findInBackground:query account:[SLAccount accountFromObject:self.listItem] block:callbackBlock];
}


-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];

    [self performSegueWithIdentifier:@"UnwindToList" sender:self];

    return YES;
}


@end
