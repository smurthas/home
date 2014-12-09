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

#import <SlabClient/SLAccount.h>
#import <SlabClient/SlabClient.h>
#import <SlabClient/SLCrypto.h>
#import <SlabClient/SLBase.h>
#import <SlabClient/SLIdentity.h>

#import <Lockbox/Lockbox.h>
#import <NWPusher.h>

@interface XYZAppDelegate ()

@property SLBase *defaultBase;
@property NSString *appID;
@property NSData *deviceToken;

@end

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


        [SLAccount becomeWithKeyPair:@{@"publicKey":publicKey, @"secretKey": secretKey} accountID:accountID appID:appID baseURL:baseURL block:^(BOOL succeeded, NSError *error) {
            if (error != nil) {
                NSLog(@"error becoming in bg %@", error);
                return;
            }

            [Lockbox setDictionary:@{
                 @"public_key": publicKey,
                 @"secret_key": secretKey,
                 @"account_id": accountID,
                 @"app_id": appID,
                 @"base_url": baseURL
            } forKey:@"slab_info"];
            [self became];
        }];
        
    } else if([url.path isEqualToString: @"/accept_invite"]) {
        [self acceptInviteWithToken:query[@"token"]
                            baseUrl:query[@"base_url"]
                          accountID:query[@"account_id"]
                       collectionID:query[@"collection_id"]];
    } else {
        NSLog(@"An unknown action was passed.");
    }
    
    return NO;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.defaultBase = [SLBase baseWithBaseURL: @"http://slab-base.herokuapp.com"
                               andManagerToken: @"kfLFL5zLR62S42keuCaSUakZ2n1z2PZTt3Urorp7CfspxuLsVZp9HeuMWC7MEP8Py3cQiM7EhoURqZQSb98sq19"];
    self.appID = @"myTodos";


    // PUSHER
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        NSLog(@"Requesting permission for push notifications..."); // iOS 8
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:
                                                UIUserNotificationTypeAlert categories:nil];
        [UIApplication.sharedApplication registerUserNotificationSettings:settings];
//    } else {
//        NSLog(@"Registering device for push notifications..."); // iOS 7 and earlier
//        [UIApplication.sharedApplication registerForRemoteNotificationTypes:
//         UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
//         UIRemoteNotificationTypeSound];
    }
    // REHSUP

    NSDictionary *slabInfo = [Lockbox dictionaryForKey:@"slab_info"];

    if (slabInfo == nil || slabInfo[@"secret_key"] == nil || slabInfo[@"public_key"] == nil ||
        slabInfo[@"account_id"] == nil || slabInfo[@"app_id"] == nil ||
        slabInfo[@"base_url"] == nil) {

        NSLog(@"creating account");
        NSDictionary *keyPair = [SLCrypto generateKeyPair];
        SLIdentity * identity = [SLIdentity identityWithKeyPair:keyPair];

        [self.defaultBase createAccountForApp:self.appID identity:identity block:^(NSString *accountID, NSError *error) {

            [SLAccount becomeWithKeyPair:keyPair accountID:accountID appID:self.appID baseURL:[self.defaultBase baseURL] block:^(BOOL succeeded, NSError *error) {

                [Lockbox setDictionary:@{
                     @"public_key": keyPair[@"publicKey"],
                     @"secret_key": keyPair[@"secretKey"],
                     @"account_id": accountID,
                     @"app_id": self.appID,
                     @"base_url": [self.defaultBase baseURL]
                     } forKey:@"slab_info"];

                NSLog(@"created account");

                [self became];
            }];
        }];
    } else {
        NSLog(@"loaded from keychain");
        [SLAccount becomeWithKeyPair:@{@"secretKey":slabInfo[@"secret_key"], @"publicKey": slabInfo[@"public_key"]} accountID:slabInfo[@"account_id"] appID:slabInfo[@"app_id"] baseURL:slabInfo[@"base_url"] block:^(BOOL succeeded, NSError *error) {
            [self became];
        }];
    }

    return YES;
}

- (void) acceptInviteWithToken:(NSString *)token baseUrl:(NSString *)baseUrl accountID:(NSString *)accountID collectionID:(NSString *)collectionID {

    SLAccount *remoteAccount = [SLAccount accountWithBaseUrl:baseUrl appID:self.appID accountID:accountID keyPair:@{@"secretKey":[[SLAccount currentAccount] getSecretKey], @"publicKey": [[SLAccount currentAccount] getPublicKey]}];
    NSString *deviceTokenString = [SLCrypto stringWithHexFromData:self.deviceToken];
    NSLog(@"sending along deviceToken: %@", deviceTokenString);

    NSMutableDictionary *appData = [[NSMutableDictionary alloc] init];

    if (deviceTokenString != nil) {
        appData[@"deviceToken"] = deviceTokenString;
    }

    [[SlabClient sharedClient] convertTemporaryIdentity:token
                                          remoteAccount:remoteAccount
                                            withAppData:appData
                                                  block:^(NSError *error) {
        // TODO: sort out how to manage multiple bases and multiple accounts
        //[SLAccount become:tempAccount];

        // TODO: check if we already have access to this collection

        NSMutableDictionary *grants = [[NSMutableDictionary alloc] init];
        grants[[[SLAccount currentAccount] getPublicKey]] = @{
            @"readAttributes": @YES,
            @"modifyAttributes": @YES
        };
        NSMutableDictionary *collectionAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
            @"type": @"list",
            @"_grants": grants,
            @"pointer": @{
                @"base_url": baseUrl,
                @"account_id": accountID,
                @"collection_id": collectionID
            }
        }];

        [[SlabClient sharedClient] createCollectionWithAttributes:collectionAttributes
                                                            block:^(NSDictionary *collection, NSError *error) {
            [((XYZListsListTableViewController*)((UINavigationController*)self.window.rootViewController).visibleViewController) loadInitialData:^(NSError *error) {
                NSLog(@"reloaded the root view controller!");
            }];
        }];
    }];
}

- (void)became {
    XYZToDoListTableViewController *mainViewController = (XYZToDoListTableViewController*)((UINavigationController*)self.window.rootViewController).topViewController;

    [mainViewController loadInitialData:^(NSError *error) {

        if (error != nil) {
            NSLog(@"error loading initial data %@", error);
            return;
        }

    }];
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


// PUSHER
- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings
{
    NSLog(@"Registering device for push notifications..."); // iOS 8
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token
{
    NSLog(@"Registration successful, bundle identifier: %@, mode: %@, device token: %@",
          [NSBundle.mainBundle bundleIdentifier], [self modeString], token);
    self.deviceToken = token;
    NSURL *url = [NSBundle.mainBundle URLForResource:@"pusher.p12" withExtension:nil];
    NSData *pkcs12 = [NSData dataWithContentsOfURL:url];
    NSError *error = nil;
    NWPusher *pusher = [NWPusher connectWithPKCS12Data:pkcs12 password:@"blargh123" error:&error];
    if (pusher) {
        NSLog(@"Connected to APNs");

        NSString *payload = @"{\"aps\":{\"alert\":\"Testing.. from app\"}}";
        NSString *stringToken = [SLCrypto stringWithHexFromData:token];
        NSError *error = nil;
        BOOL pushed = [pusher pushPayload:payload token:stringToken identifier:rand() error:&error];
        if (pushed) {
            NSLog(@"Pushed to APNs");
        } else {
            NSLog(@"Unable to push: %@", error);
        }
    } else {
        NSLog(@"Unable to connect: %@", error);
    }
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register: %@", error);
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)notification completionHandler:(void(^)())completionHandler
{
    NSLog(@"Received push notification: %@, identifier: %@", notification, identifier); // iOS 8

    [((XYZListsListTableViewController*)((UINavigationController*)self.window.rootViewController).visibleViewController) loadInitialData:^(NSError *error) {
        NSLog(@"reloaded the root view controller after push!");
        completionHandler();
    }];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)notification
{
    NSLog(@"Received push notification: %@", notification); // iOS 7 and earlier
}

- (NSString *)modeString
{
#if DEBUG
    return @"Development (sandbox)";
#else
    return @"Production";
#endif
}
// REHSUP

@end
