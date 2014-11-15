//
//  SLBase.h
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SLIdentity.h"

@interface SLBase : NSObject

@property NSString *managerToken;
@property NSString *baseURL;

+ (SLBase*)baseWithBaseURL:(NSString*)baseUrl andManagerToken:(NSString*)managerToken;

- (void)getAccountsForApp:(NSString*)appID block:(void (^)(NSArray* accounts, NSError* error))callbackBlock;
- (void)createAccountAndIdentityForApp:(NSString*)appID block:(void (^)(NSDictionary* identity, NSString* accountID, NSError* error))callbackBlock;
- (void)createAccountForApp:(NSString*)appID identity:(SLIdentity*)identity block:(void (^)(NSString* accountID, NSError* error))callbackBlock;
- (void)createGrantForApp:(NSString*)appID accountID:(NSString*)accountID permissions:(NSDictionary*)permissions keyPair:(NSDictionary*)keyPair block:(void (^)(NSDictionary* info, NSError* error))callbackBlock;
@end