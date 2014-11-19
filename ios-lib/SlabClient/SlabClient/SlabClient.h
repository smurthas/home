//
//  SlabClient.h
//  SlabClient
//
//  Created by Simon Murtha Smith on 10/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SLQuery.h"
#import "SLAccount.h"

@interface SlabClient : NSObject

+ (SlabClient *) sharedClient;

+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI;


- (void) saveInBackground:(NSMutableDictionary*)object toCollection:(NSMutableDictionary*)collection;
- (void) batchUpdate:(NSArray*)objects toCollection:(NSDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock;
- (void) deleteInBackground:(NSDictionary*)object fromCollectionID:(NSString*)collectionID;
- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSDictionary*)collection;

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock;

- (void) getKnownIdentities:(void (^)(NSArray *identities, NSError* error))callbackBlock;
- (void) getIdentities:(NSArray*)publicKeys block:(void (^)(NSArray *identities, NSError* error))callbackBlock;
- (void) getTemporaryIdentities:(NSArray*)tokens block:(void (^)(NSArray *identities, NSError* error))callbackBlock;

- (void) createCollectionWithAttributes:(NSDictionary*)attributes block:(void (^)(NSDictionary* collection, NSError* error))callbackBlock;

- (void) findInBackground:(SLQuery*)query account:(SLAccount *)account block:(void (^)(NSArray *objects, NSError* error))callbackBlock;

- (void) createTemporaryIdentity:(NSDictionary*)parameters block:(void (^)(NSString *token, NSError* error))callbackBlock;
- (void) createTemporaryIdentity:(NSDictionary*)parameters account:(SLAccount *)account block:(void (^)(NSString *token, NSError* error))callbackBlock;
- (void) convertTemporaryIdentity:(NSString *)token remoteAccount:(SLAccount*)account block:(void (^)(NSError* error))callbackBlock;

@end
