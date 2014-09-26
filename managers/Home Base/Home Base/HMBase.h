//
//  HMApp.h
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMBase : NSObject

@property NSString *managerToken;
@property NSString *baseURL;

+ (HMBase*)baseWithBaseURL:(NSString*)baseUrl andManagerToken:(NSString*)managerToken;

- (void)getAccountsForApp:(NSString*)appID block:(void (^)(NSArray* accounts, NSError* error))callbackBlock;
- (void)createAccountAndApp:(NSString*)appID block:(void (^)(NSDictionary* info, NSError* error))callbackBlock;
- (void)createGrantForApp:(NSString*)appID accountID:(NSString*)accountID permissions:(NSDictionary*)dictionary block:(void (^)(NSDictionary* info, NSError* error))callbackBlock;
@end
