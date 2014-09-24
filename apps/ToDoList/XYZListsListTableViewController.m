//
//  XYZListsListTableViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/20/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZListsListTableViewController.h"
#import "XYZToDoListTableViewController.h"
#import "XYZAddListViewController.h"

#import "HMAccount.h"
#import "HMQuery.h"

@interface XYZListsListTableViewController ()

@property NSMutableArray *lists;

@end

@implementation XYZListsListTableViewController


- (void) loadInitialData:(void (^)(NSError* error))callbackBlock {
    HMQuery *query = [HMQuery queryWithClassName:@"lists"];
//    [query whereKey:@"logged" equalTo:@NO];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"objects %@", objects);
        NSLog(@"error %@", error);
        if (error == nil) {
            self.lists = [[NSMutableArray alloc] initWithArray:objects];
            NSLog(@"listItems %@", self.lists);
            [self.tableView reloadData];
        }
        callbackBlock(error);
    }];
}

- (IBAction)login:(id)sender {
    //NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoDKn2wdotXbLheSn09g/\nsjAc0rhYb8+KdQDB+zKp9Cq63qJDfR+r8sBn5QLz98LLEWKi7Q3v61Ih9ySUFlqy\nF/dCbugu+Xc8zIxK/8kWk+U1/umc7M6jKD7kw7qhomj/pieEw4UQ9cH0CdxM3U6w\noRSIU/pBix4K1nu8bgpgYzam1e9QTRu+yPw0a0DIsB8Ma7QDFbtcRBm1yi21yQkA\ne1orm2Az7ETZ1pZrGXrcBqcJ/IM3kWSh+mY1earsE1ihgeWueJqBd77zRYI5+0Uf\nN/DxtZUGOIPpKmY20zBgZM4aQO/Il+ZVIRVMJuB0fpimPawFLx8rPyuLbKjjfxyy\n9QIDAQAB\n-----END PUBLIC KEY-----";
    
    NSString *publicKey = @"myTodos";
    
    [HMAccount loginWithPublicKey:publicKey callbackURI:@"todos://com.sms.todos/auth_complete"];
    
    /*
    NSArray *accounts = @[
        @{@"token": @"m4uvSQwvhcSgrL3DWAZwdCJHmbNQcCPytosuds9x59qKTpUcjB7mgQRPKy4xyt6hZrxVoL2sTDKaXUVRQDhcWWFn5w1MjsKqR7PjPcd68gxEQjkyjYiC2VwwvAjxQQ98fktAVPieZgiGjxjpLGV1KKj4SMJt3nzWrZs3akm5YJn9zv8SRKr2eXNiXcdBL2KnjPDntzRKC34V9EiWhxYbeJ9pp3K4t8ZUdNcHyL9B4AuwuWgDSQXTaqxWJSoyEzATymqTfU4JsS5NN5jhVrNwXMsxv1gybZXZBA6ARD1q6gZtEu8Z2JrmwEsr86WQpGK4eLdiC43adT6YMiHsrBsHHW6LmeHpKreHkC7k3gVn42HsPzU2ak6DWniEPm5GpT97TwxGnGn98gStjTWMioH1PQgpG1hbVLpE8iRr8N795q7oFsNFtEVFerVTa6A5fhrBkmQXeMk1zaEaXdrHnyvY2NJchPw5krt9YPLACtbTN4jdfWcBGk5tnrPf4Nh8HuM3HDMczPf3BnbVAHcUB7p5YhQwmqAvYwDhareydtNMY9LeMXxRpEHWFD6FL18iEqxdMdm7k2JH15fvzmE3MowvziBG1Q9Hed5BF8tcNwxQQd4ngSDQSVeS2nY3yqTtDPz6knnAwDPohb8brUDSNAkjJEbrhHngVeudLMY7E",
          @"baseURL": @"http://localhost:2750"},
        @{@"token": @"", @"baseURL": @""}];
    
    [UIActionSheet alloc]
    
    [HMAccount becomeWithToken:token baseURL:baseURL block:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"error becoming in bg %@", error);
            return;
        }
        
        XYZToDoListTableViewController *mainViewController = (XYZToDoListTableViewController*)((UINavigationController*)self.window.rootViewController).topViewController;
        
        [mainViewController loadInitialData:^(NSError *error) {
            
            if (error != nil) {
                NSLog(@"error loading initial data %@", error);
                return;
            }
            
            NSLog(@"reloaded after login");
        }];
    }];*/
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    XYZAddListViewController *source = [segue sourceViewController];
    NSLog(@"listItem: %@", source.listItem);
    if (source.listItem != nil) {
        [self.lists addObject:source.listItem];
        [self.tableView reloadData];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"self.lists class %@", [self.lists class]);
    NSLog(@"self.lists %@", self.lists);
    NSLog(@"self.lists.count %@", @([self.lists count]));
    return [self.lists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListListPrototypeCell" forIndexPath:indexPath];
    
    NSLog(@"self.lists class %@", [self.lists class]);
    NSLog(@"self.lists %@", self.lists);
    NSLog(@"self.lists.count %@", @([self.lists count]));
    cell.textLabel.text = [self.lists objectAtIndex:indexPath.row][@"name"];
    // Configure the cell...
    
    NSLog(@"returning cell");
    return cell;
}


- (IBAction)refresh:(id)sender
{
    NSLog(@"Refreshing");
    [self loadInitialData:^(NSError *error) {
        [(UIRefreshControl *)sender endRefreshing];
    }];
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"preparing for segue");
    
    if ([[segue destinationViewController] class] == [XYZToDoListTableViewController class]) {
        XYZToDoListTableViewController *tvc = (XYZToDoListTableViewController*)[segue destinationViewController];
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        
        tvc.listItem = [self.lists objectAtIndex:path.row];
    }
    
}


@end
