//
//  XYZAddToDoItemViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZAddToDoItemViewController.h"


#import <SlabClient/SLCrypto.h>
#import <SlabClient/SLAccount.h>
#import <SlabClient/SLQuery.h>
#import <SlabClient/SlabClient.h>


@interface XYZAddToDoItemViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;
@property (weak, nonatomic) IBOutlet UIButton *button4;
@property (weak, nonatomic) IBOutlet UIButton *button5;
@property (weak, nonatomic) IBOutlet UIButton *button6;
@property (weak, nonatomic) IBOutlet UIButton *button7;
@property (weak, nonatomic) IBOutlet UIButton *button8;


@end

@implementation XYZAddToDoItemViewController

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
    //[self loadTopTodos];
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
    if (sender == self.cancelButton) return;

    if (self.textField.text.length > 0) {
        self.toDoItem = [[NSMutableDictionary alloc] init];
        if (self.imageView.image != nil) {
            CGSize newSize = CGSizeMake(600, 600);
            UIGraphicsBeginImageContext( newSize );
            [self.imageView.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            NSData *imageData = UIImageJPEGRepresentation(newImage, 0.3);
            self.toDoItem[@"image"] = [SLCrypto stringWithHexFromData:imageData];
        }
        [self.toDoItem setValue: self.textField.text forKey:@"title"];
        [self.toDoItem setValue: @NO forKey:@"completed"];
        [self.toDoItem setValue: @NO forKey:@"logged"];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];

    [self performSegueWithIdentifier:@"UnwindToList" sender:self];

    return YES;
}


- (IBAction)addPhoto:(id)sender {

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)quickAddButton:(id)sender {
    
    NSString* text = ((UIButton*)sender).titleLabel.text;
    
    self.toDoItem = [[NSMutableDictionary alloc] init];
    [self.toDoItem setValue: text forKey:@"title"];
    [self.toDoItem setValue: @NO forKey:@"completed"];
    [self.toDoItem setValue: @NO forKey:@"logged"];
    
    [self performSegueWithIdentifier:@"UnwindToList" sender:self];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;

    [picker dismissViewControllerAnimated:YES completion:NULL];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (NSString*)cleanTitle:(NSString*)original {
    original = [[original lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSError *errorToBe = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-z]" options:NSRegularExpressionCaseInsensitive error:&errorToBe];
    return [regex stringByReplacingMatchesInString:original options:0 range:NSMakeRange(0, [original length]) withTemplate:@""];
}

- (NSArray*) findItemsInSameListAs:(NSDictionary*)item from:(NSArray*)objects {
    return [objects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [object[@"_createdAt"] caseInsensitiveCompare:item[@"_updatedAt"]] == NSOrderedAscending && [object[@"_updatedAt"] caseInsensitiveCompare:item[@"_createdAt"]] == NSOrderedDescending;
    }]];
}

- (NSArray*) findAllItems:(NSArray*)allItems coListedWith:(NSArray*)items {
    NSMutableArray* allCoListed = [NSMutableArray array];
    for (NSDictionary* item in items) {
        [allCoListed addObjectsFromArray:[self findItemsInSameListAs:item from:allItems]];
    }
    return allCoListed;
}

- (NSMutableDictionary *) groupByCleanTitle:(NSArray*)items {
    NSMutableDictionary *grouped = [[NSMutableDictionary alloc] init];
    for (NSDictionary *item in items) {
        NSString *thisCleanedTitle = [self cleanTitle:item[@"title"]];
        NSMutableArray *these = grouped[thisCleanedTitle];
        if (these == nil) {
            these = [[NSMutableArray alloc] init];
            grouped[thisCleanedTitle] = these;
        }
        [these addObject: @{
                            @"_createdAt": item[@"_createdAt"],
                            @"_updatedAt": item[@"_updatedAt"],
                            @"title": item[@"title"]
                            }];
    }
    
    return grouped;
}

- (NSMutableDictionary*) sortUpCandidatesInverse:(NSArray*)allItems withTitle:(NSString*)title {
    title = [self cleanTitle:title];
    
    NSDictionary *grouped = [self groupByCleanTitle:allItems];
    int total_unique = (int)[grouped allKeys].count;
//    NSLog(@"grouped all keys: %@", [grouped allKeys]);
    int K = 1;
    NSMutableDictionary *Ps = [NSMutableDictionary dictionary];
    
    for (NSString* proposal in grouped) {
        NSArray* group = (NSArray*)grouped[proposal];
        double P_proposal = ((double)group.count) / ((double)allItems.count);
        NSMutableDictionary *groupedCoListedItems = [self groupByCleanTitle:[self findAllItems:allItems coListedWith:group]];
        [groupedCoListedItems removeObjectForKey:proposal];
//        NSLog(@"For proposal \"%@\", groupedCoListedItems: %@", proposal, [groupedCoListedItems allKeys]);
        
        if (groupedCoListedItems[title] == nil) {
            groupedCoListedItems[title] = [NSArray array];
        }
        
        int count_onlist_given_proposal = (int)((NSArray*)groupedCoListedItems[title]).count;
        
        int count_total_given_proposal = 0;
        for (NSString* coListedGroupKey in groupedCoListedItems) {
            count_total_given_proposal += (int)((NSArray*)groupedCoListedItems[coListedGroupKey]).count;
        }
//        int count_total_unique_given_proposal = (int)[groupedCoListedItems allKeys].count;
        
        double P_onlist_given_proposal = ((double)(count_onlist_given_proposal + K)) / ((double)(count_total_given_proposal + (K*(total_unique))));
        double P_proposal_given_onlist = P_onlist_given_proposal * P_proposal;
        Ps[proposal] = @{
            @"proposal": group,
            @"P":[NSNumber numberWithDouble:P_proposal_given_onlist]
        };
    }
    
        
    return Ps;
//    grouped = groupByCleanTitle(all)
//    K = 1
//    Ps = []
//    for each proposal in grouped.keys {
//        P_proposal = grouped[proposal].count / all.count;
//        groupedCoListedWithProposal = groupByCleanTitle(findCoListed(all, grouped[proposal]))
//        
//        count_onlist_given_proposal = 0
//        if (groupedCoListedWithProposal[onlistCleaned] != nil) {
//            count_onlist_given_proposal = groupedCoListedWithProposal[onlistCleaned].count;
//        }
//        count_total_given_proposal = reduce(groupedCoListedWithProposal, sum of all counts)
//        count_total_unique_given_proposal = groupedCoListedWithProposal.keys.count;
//        
//        P_onlist_given_proposal = (count_onlist_given_proposal + K) / (count_total_given_proposal + (K*(count_total_unique_given_proposal + 1)))
//        
//        P_proposal_given_onlist = P_onlist_given_proposal * P_proposal
//        Ps.push({proposal: proposal, P:P_proposal_given_onlist})
//    }
//    
//    
//    sort Ps P value, descending
}

- (NSArray*) sortUpCandidates:(NSArray*)allItems from:(NSArray*)foundMatches colistedWith:(NSString*)title {
    NSMutableArray *allColisted = [[NSMutableArray alloc] init];
    
    for (NSDictionary* match in foundMatches) {
        [allColisted addObjectsFromArray:[self findItemsInSameListAs:match from:allItems]];
    }
//    NSLog(@"allColisted: %lu", (unsigned long)allColisted.count);
    
    NSMutableDictionary *grouped = [self groupByCleanTitle:allColisted];
    [grouped removeObjectForKey:title];
    
    NSMutableArray *sorted = [NSMutableArray array];
    for (NSString *key in grouped) {
        [sorted addObject: grouped[key]];
    }
    
    [sorted sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return ((NSArray*)obj2).count - ((NSArray*)obj1).count;
    }];
    
    return sorted;
}

- (void) loadTopTodos {
    SLQuery *query = [SLQuery objectQueryWithCollectionName:self.listItem[@"_id"]];
    NSLog(@"loading initial data from self.listItem %@", self.listItem);
    
    [[SlabClient sharedClient] findInBackground:query account:[SLAccount accountFromObject:self.listItem] block:^(NSArray *objects, NSError *error) {
        NSArray *inListNow = [objects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            return ![object[@"logged"]  isEqual: @YES];
        }]];
        
        if (inListNow.count == 0) {
            inListNow = @[@{
                          @"title": @"ascknjewlucnaew3d8nsdcjnsdcladusf"
                          }];
        }
        
        NSLog(@"inListNow: %@", inListNow);
        NSMutableDictionary *allCandidates = [NSMutableDictionary dictionary];
        for (NSDictionary *itemInList in inListNow) {
            NSString* filterTilte = itemInList[@"title"];
            NSString *cleanedTitle = [self cleanTitle:filterTilte];
            NSDictionary *inverseCandidates = [self sortUpCandidatesInverse:objects withTitle:filterTilte];
//            NSLog(@"inverseCandidates: %@", inverseCandidates);
            for (NSString *proposal in inverseCandidates) {
                if (allCandidates[proposal] == nil) {
                    allCandidates[proposal] = inverseCandidates[proposal];
                } else {
                    [((NSMutableArray*)allCandidates[proposal][@"proposal"]) addObjectsFromArray:inverseCandidates[proposal][@"proposal"]];
                    allCandidates[proposal][@"P"] = [NSNumber numberWithDouble: [((NSNumber*)allCandidates[proposal][@"P"]) doubleValue] + [((NSNumber*)inverseCandidates[proposal][@"P"]) doubleValue]];
                }
            }
        }
        
        NSMutableArray *sortedCandidates = [NSMutableArray array];
        for (NSString* proposal in allCandidates) {
            [sortedCandidates addObject:allCandidates[proposal]];
        }
        [sortedCandidates sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            double diff = [((NSNumber*)obj2[@"P"]) doubleValue] - [((NSNumber*)obj1[@"P"]) doubleValue];
            if (diff > 0) {
                return NSOrderedDescending;
            }
            if (diff < 0) {
                return NSOrderedAscending;
            }
            return NSOrderedSame;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sortedCandidates.count > 0) {
                self.button1.titleLabel.text = sortedCandidates[0][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 1) {
                self.button2.titleLabel.text = sortedCandidates[1][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 2) {
                self.button3.titleLabel.text = sortedCandidates[2][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 3) {
                self.button4.titleLabel.text = sortedCandidates[3][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 4) {
                self.button5.titleLabel.text = sortedCandidates[4][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 5) {
                self.button6.titleLabel.text = sortedCandidates[5][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 6) {
                self.button7.titleLabel.text = sortedCandidates[6][@"proposal"][0][@"title"];
            }
            if (sortedCandidates.count > 7) {
                self.button8.titleLabel.text = sortedCandidates[7][@"proposal"][0][@"title"];
            }
        });
    }];
}



@end
