//
//  SLAccount.h
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLAccount : NSObject

+ (SLAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID  keyPair:(NSDictionary*)keyPair;
+ (SLAccount*) accountFromObject:(NSDictionary*)object;
+ (void) becomeWithKeyPair:(NSDictionary*)keyPair accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock;
+ (void) become:(SLAccount *)anotherAccount;

+ (SLAccount*) currentAccount;


- (NSString *) getAccountID;
- (NSString *) getBaseUrl;
- (NSString *) getPublicKey;
- (NSString *) getSecretKey;


- (NSString*) URLStringForAccount;
- (NSString*) URLStringForCollection:(NSString*)collection;
- (NSString*) URLStringForObject:(NSDictionary*)object collection:(NSString*)collection;


@end
