//
//  HMAccount.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMAccount : NSObject

+ (HMAccount*) accountWithBaseUrl:(NSString*)baseUrl publicKey:(NSString*)publicKey;
+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI;
+ (HMAccount*) currentAccount;
+ (void) becomeWithToken:(NSString*)token accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock;


- (NSString *) getToken;
- (NSString *) getBaseUrl;
- (NSString *) getPublicKey;
- (void) saveInBackground:(NSDictionary*)object toCollection:(NSString*)collection;
- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection;
- (void) createGrantWithAccount:(HMAccount*)toAccount forResource:(NSDictionary *)resource block:(void (^)(NSDictionary* grant, NSError* error))callbackBlock;
- (void)sendGrant:(NSDictionary*)grant toAccount:(HMAccount*)toAccount forResource:(NSDictionary*)resource;
- (NSString*) URLStringForCollection:(NSString*)collection;

@end
