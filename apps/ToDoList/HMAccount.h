//
//  HMAccount.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HMQuery.h"

@interface HMAccount : NSObject

+ (HMAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID token:(NSString*)token;
+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI;
+ (HMAccount*) currentAccount;
+ (void) becomeWithToken:(NSString*)token accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock;


- (NSString *) getToken;
- (NSString *) getAccountID;
- (NSString *) getBaseUrl;
- (NSString *) getPublicKey;

- (void) saveInBackground:(NSDictionary*)object toCollection:(NSString*)collection;
- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection;

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock;

- (void) createGrantWithAccountID:(NSString *)toAccountID block:(void (^)(NSDictionary *, NSError *))callbackBlock;
- (void)sendGrant:(NSDictionary*)grant toAccount:(HMAccount*)toAccount forResource:(NSDictionary*)resource;

- (void) createCollectionWithAttributes:(NSDictionary*)attributes block:(void (^)(NSDictionary* collection, NSError* error))callbackBlock;

- (void) findInBackground:(HMQuery*)query block:(void (^)(NSArray *objects, NSError* error))callbackBlock;

- (NSString*) URLStringForAccount;
- (NSString*) URLStringForCollection:(NSString*)collection;

@end
