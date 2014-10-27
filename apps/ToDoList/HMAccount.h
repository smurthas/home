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

+ (HMAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID  keyPair:(NSDictionary*)keyPair;
+ (HMAccount*) accountFromObject:(NSDictionary*)object;
+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI;
+ (HMAccount*) currentAccount;
+ (void) becomeWithKeyPair:(NSDictionary*)keyPair accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock;
+ (void) become:(HMAccount *)anotherAccount;


- (NSString *) getAccountID;
- (NSString *) getBaseUrl;
- (NSString *) getPublicKey;
- (NSString *) getSecretKey;

- (void) saveInBackground:(NSDictionary*)object toCollection:(NSString*)collection;
- (void) batchUpdate:(NSArray*)objects toCollection:(NSString*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock;
- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection;

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock;

- (void) getKnownIdentities:(void (^)(NSArray *identities, NSError* error))callbackBlock;
- (void) getIdentities:(NSArray*)publicKeys block:(void (^)(NSArray *identities, NSError* error))callbackBlock;
- (void) getTemporaryIdentities:(NSArray*)tokens block:(void (^)(NSArray *identities, NSError* error))callbackBlock;

- (void) createCollectionWithAttributes:(NSDictionary*)attributes block:(void (^)(NSDictionary* collection, NSError* error))callbackBlock;

- (void) findInBackground:(HMQuery*)query block:(void (^)(NSArray *objects, NSError* error))callbackBlock;

- (void) createTemporaryIdentity:(NSDictionary*)createTemporaryIdentity block:(void (^)(NSString *token, NSError* error))callbackBlock;
- (void) convertTemporaryIdentity:(NSString *)token block:(void (^)(NSError* error))callbackBlock;


- (NSString*) URLStringForAccount;
- (NSString*) URLStringForCollection:(NSString*)collection;

@end
