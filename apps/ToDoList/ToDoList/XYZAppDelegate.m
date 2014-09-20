//
//  XYZAppDelegate.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZAppDelegate.h"
#import "XYZToDoListTableViewController.h"

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
    if ([url.scheme isEqualToString: @"todos"]) {
        NSLog(@"todos!");
        
        // check our `host` value to see what screen to display
        if ([url.path isEqualToString: @"/auth_complete"]) {
            NSLog(@"query %@", url.query);
            
            NSDictionary *query = [self queryDictFromString:url.query];
            NSString *token = query[@"token"];
            NSString *baseURL = query[@"base_url"];
            
            NSLog(@"token: %@", token);
            
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
            }];
            NSLog(@"source: %@", sourceApplication);
            
        } else {
            NSLog(@"An unknown action was passed.");
        }
    } else {
        NSLog(@"We were not opened with todos.");
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
