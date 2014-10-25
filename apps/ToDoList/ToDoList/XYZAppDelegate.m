//
//  XYZAppDelegate.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZAppDelegate.h"
#import "XYZToDoListTableViewController.h"
#import "XYZListsListTableViewController.h"

#import "HMAccount.h"

@implementation XYZAppDelegate



- (NSString *)stringByDecodingURLFormat:(NSString *)string
{
    NSString *result = [(NSString *)string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSDictionary*) queryDictFromString:(NSString*)queryString {
    
    NSMutableDictionary *queryDict = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [queryString componentsSeparatedByString:@"&"];
    NSLog(@"compoentns %@", urlComponents);
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [pairComponents objectAtIndex:0];
        NSString *value = [pairComponents objectAtIndex:1];
        value = [self stringByDecodingURLFormat:value];
        
        [queryDict setObject:value forKey:key];
    }
    
    return queryDict;
}


-(BOOL) application: (UIApplication * ) application openURL: (NSURL * ) url sourceApplication: (NSString * ) sourceApplication annotation: (id) annotation {

    // TODO: make this more real
    NSString *appID = @"myTodos";

    if (![url.scheme isEqualToString: @"todos"])  return NO;

    NSDictionary *query = [self queryDictFromString:url.query];

    // check our `host` value to see what screen to display
    if ([url.path isEqualToString: @"/auth_complete"]) {

        NSString *publicKey = query[@"public_key"];
        NSString *secretKey = query[@"secret_key"];
        NSString *accountID = query[@"account_id"];
        NSString *baseURL = query[@"base_url"];


        [HMAccount becomeWithKeyPair:@{@"publicKey":publicKey, @"secretKey": secretKey} accountID:accountID appID:appID baseURL:baseURL block:^(BOOL succeeded, NSError *error) {
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

            }];
        }];
        
    } else if([url.path isEqualToString: @"/accept_invite"]) {
        NSDictionary *keyPair = @{@"secretKey": [[HMAccount currentAccount] getSecretKey], @"publicKey": [[HMAccount currentAccount] getPublicKey]};
        HMAccount *tempAccount = [HMAccount accountWithBaseUrl:query[@"base_url"] appID:appID accountID:query[@"account_id"] keyPair:keyPair];

        [tempAccount convertTemporaryIdentity:query[@"token"] block:^(NSError *error) {
            // TODO: sort out how to manage multiple bases and multiple accounts
            //[HMAccount become:tempAccount];

            // TODO: check if we already have access to this collection
            
            NSMutableDictionary *grants = [[NSMutableDictionary alloc] init];
            grants[keyPair[@"publicKey"]] = @{
                @"readAttributes": @YES,
                @"modifyAttributes": @YES
            };
            NSMutableDictionary *collectionAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
                @"type": @"list",
                @"_grants": grants,
                @"pointer": @{
                    @"base_url": query[@"base_url"],
                    @"account_id": query[@"account_id"],
                    @"collection_id": query[@"collection_id"]
                }
            }];

            [[HMAccount currentAccount] createCollectionWithAttributes:collectionAttributes
                block:^(NSDictionary *collection, NSError *error) {

                [((XYZListsListTableViewController*)((UINavigationController*)self.window.rootViewController).visibleViewController) loadInitialData:^(NSError *error) {
                    NSLog(@"reloaded the root view controller!");
                }];
            }];
        }];
    } else {
        NSLog(@"An unknown action was passed.");
    }
    
    return NO;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
