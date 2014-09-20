//
//  HMAccount.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMAccount : NSObject

+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI;
+ (HMAccount*) currentAccount;
+ (void) becomeWithToken:(NSString*)token baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock;

- (NSString *) getToken;
- (NSString *) getBaseUrl;
- (void) saveInBackground:(NSDictionary*)object toCollection:(NSString*)collection;
- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection;

@end
