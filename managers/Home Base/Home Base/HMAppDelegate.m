//
//  HMAppDelegate.m
//  Home Base
//
//  Created by Simon Murtha Smith on 9/18/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMAppDelegate.h"

#import <CommonCrypto/CommonDigest.h>

#import "HMBase.h"
#import "SLIdentity.h"

@import UIKit;

@interface HMAppDelegate ()

@property NSString *appID;
@property NSString *redirectURI;

@property NSMutableArray *bases;

@property HMBase *base;
@property SLIdentity *identity;

@end

@implementation HMAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;



+ (NSString *)stringByDecodingURLFormat:(NSString *)string
{
    NSString *result = [(NSString *)string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

+ (NSDictionary*) queryDictFromString:(NSString*)queryString {
    
    NSMutableDictionary *queryDict = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [pairComponents objectAtIndex:0];
        NSString *value = [pairComponents objectAtIndex:1];
        value = [HMAppDelegate stringByDecodingURLFormat:value];
        
        [queryDict setObject:value forKey:key];
    }
    
    return queryDict;
}

-(NSString*)sha256HashFor:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

-(BOOL) application: (UIApplication * ) application openURL: (NSURL * ) url sourceApplication: (NSString * ) sourceApplication annotation: (id) annotation {
    if ([url.scheme isEqualToString: @"home"]) {
        // check our `host` value to see what screen to display
        if ([url.host isEqualToString: @"authstart"]) {
            NSLog(@"query %@", url.query);
            
            NSDictionary *query = [HMAppDelegate queryDictFromString:url.query];
            
            self.appID = query[@"pubkey"];
            self.redirectURI = query[@"redirect_uri"];
            
            
            if (self.bases && self.bases.count > 1) {
                [self promptForBase];
            } else {
                [self promptForIdentity];
            }
        } else if ([url.host isEqualToString: @"authcomplete"]) {
            //[self.viewController presentAboutScreen];
        } else {
            NSLog(@"An unknown action was passed.");
        }
    } else {
        NSLog(@"We were not opened with birdland.");
    }
    return NO;
}

- (void) promptForBase {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title Here"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    for (HMBase *base in self.bases) {
        [actionSheet addButtonWithTitle:base.baseURL];
    }
    
    
    actionSheet.tag = 0;
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet showInView:self.window.rootViewController.view];
}

- (void) promptForIdentity {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Which Identity?"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    [actionSheet addButtonWithTitle:@"Create New Identity"];
    for (SLIdentity *identity in [SLIdentity getIdentities]) {
        [actionSheet addButtonWithTitle:identity.publicKey];
    }


    actionSheet.tag = 1;
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet showInView:self.window.rootViewController.view];
}


- (void) promptForAccount {
    [self.base getAccountsForApp:self.appID block:^(NSArray *accounts, NSError *error) {
        NSLog(@"accounts: %@, accounts.count %lu", accounts, (unsigned long)accounts.count);
        if (!accounts || !accounts.count || accounts.count < 1) {
            NSString *title = @"Do you want to create a new account for ";

            title = [[title stringByAppendingString:self.appID] stringByAppendingString:@"?"];

            UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:title
                                                              message:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                                    otherButtonTitles:@"No", @"Yes", nil];
            [myAlert show];
        } else {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Which account?"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
            [actionSheet addButtonWithTitle:@"Create New Account"];
            for (NSString *accountID in accounts) {
                [actionSheet addButtonWithTitle:accountID];
            }

            actionSheet.tag = 2;
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
            [actionSheet showInView:self.window.rootViewController.view];

        }
        
    }];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"tag: %li", popup.tag);
    if (popup.tag == 0) { // prompted for base
        [self handleBasePromptResponse:popup clickedButtonAtIndex:buttonIndex];
    } else if (popup.tag == 1) { // prompted for identity
        [self handleIdentityPromptResponse:popup clickedButtonAtIndex:buttonIndex];
    } else if (popup.tag == 2) { // prompted for account
        [self handleAccountPromptResponse:popup clickedButtonAtIndex:buttonIndex];
    }
}


- (void)handleBasePromptResponse:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    // prompted for base
    if (buttonIndex == popup.cancelButtonIndex) return;

    self.base = self.bases[buttonIndex];
    [self promptForIdentity];
}

- (void)handleIdentityPromptResponse:(UIActionSheet*) popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    // create identity button is first
    if (buttonIndex == 0) {
        [self.base createAccountAndIdentityForApp:self.appID block:^(NSDictionary *keyPair, NSString *accountID, NSError *error) {
            [self redirectWithKeyPair:keyPair accountID:accountID];
        }];
    } else if (buttonIndex == popup.cancelButtonIndex) {
        return;
    } else {
        NSString *publicKey = [popup buttonTitleAtIndex:buttonIndex];
        self.identity = [SLIdentity identityForPublicKey:publicKey];
        [self promptForAccount];
    }
}

- (void)handleAccountPromptResponse:(UIActionSheet*) popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    // create account button is first
    if (buttonIndex == 0) {
        [self.base createAccountForApp:self.appID identity:self.identity block:^(NSString *accountID, NSError *error) {
            [self redirectWithKeyPair:[self.identity keyPair] accountID:accountID];
        }];
    } else if (buttonIndex == popup.cancelButtonIndex) {
        return;
    } else {
        NSString *accountID = [popup buttonTitleAtIndex:buttonIndex];
        NSDictionary *keyPair = [self.identity keyPair];

        // TODO: ensure identity has access, if not prompt to grant
        [self redirectWithKeyPair:keyPair accountID:accountID];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"index %ld", (long)buttonIndex);
    NSLog(@"appID %@, would open %@", self.appID, self.redirectURI);
    [self.base createAccountAndIdentityForApp:self.appID block:^(NSDictionary *keyPair, NSString *accountID, NSError *error) {
        [self redirectWithKeyPair:keyPair accountID:accountID];
    }];
}

- (void) redirectWithKeyPair:(NSDictionary*)keyPair accountID:(NSString*)accountID {
    NSString *url =[[[[[[[[self.redirectURI
        stringByAppendingString:@"?secret_key="] stringByAppendingString:keyPair[@"secretKey"]]
        stringByAppendingString:@"&public_key="] stringByAppendingString:keyPair[@"publicKey"]]
        stringByAppendingString:@"&account_id="] stringByAppendingString:accountID]
        stringByAppendingString:@"&base_url="] stringByAppendingString:self.base.baseURL];
    NSLog(@"redirecting to %@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}





- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.bases = [[NSMutableArray alloc] init];
    
    [self.bases addObject: [HMBase baseWithBaseURL:@"http://localhost:2570" andManagerToken:@"kfLFL5zLR62S42keuCaSUakZ2n1z2PZTt3Urorp7CfspxuLsVZp9HeuMWC7MEP8Py3cQiM7EhoURqZQSb98sq19"]];
    
    
    [self.bases addObject: [HMBase baseWithBaseURL:@"http://localhost:2571" andManagerToken:@"4TnuvjZtk5nVR3xVKs9ANywHhYfxBBhxUYP52BVhEUq3a9rCndRCqb99wFUtczuh3kgXc3HziKfYvoESPnTu2SVZ"]];

    [self.bases addObject: [HMBase baseWithBaseURL:@"http://slab-base.herokuapp.com"
        andManagerToken:@"kfLFL5zLR62S42keuCaSUakZ2n1z2PZTt3Urorp7CfspxuLsVZp9HeuMWC7MEP8Py3cQiM7EhoURqZQSb98sq19"]];
    
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    //self.window.backgroundColor = [UIColor whiteColor];
    //[self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Home_Base" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Home_Base.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



@end
