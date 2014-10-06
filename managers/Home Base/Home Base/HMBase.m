//
//  HMApp.m
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMBase.h"

#import <SlabClient/SLCrypto.h>

#import <AFNetworking.h>

@implementation HMBase

+ (HMBase*)baseWithBaseURL:(NSString*)baseUrl andManagerToken:(NSString*)managerToken {
    HMBase *base = [[HMBase alloc] init];
    base.baseURL = baseUrl;
    base.managerToken = managerToken;
    
    return base;
}

- (void)getAccountsForApp:(NSString*)appID block:(void (^)(NSArray* accounts, NSError* error))callbackBlock {
    
    NSString *url = [[self.baseURL stringByAppendingString: @"/apps/"] stringByAppendingString:appID];
    NSDictionary *parameters = @{@"manager_token": self.managerToken};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)createAccountAndIdentityForApp:(NSString*)appID block:(void (^)(NSDictionary* identity, NSString* accountID, NSError* error))callbackBlock {
    NSDictionary *keyPair = [SLCrypto generateKeyPair];

    [self createAccountForApp:appID identity:[SLIdentity identityWithKeyPair:keyPair] block:^(NSString *accountID, NSError *error) {
        callbackBlock(keyPair, accountID, error);
    }];
}

- (void)createAccountForApp:(NSString*)appID identity:(SLIdentity*)identity block:(void (^)(NSString* accountID, NSError* error))callbackBlock {

    NSString *url = [[self.baseURL stringByAppendingString: @"/apps/"] stringByAppendingString:appID];

    NSDictionary *parameters = @{
        @"manager_token": self.managerToken,
        @"public_key": [identity keyPair][@"publicKey"]
    };

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callbackBlock(responseObject[@"account_id"], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)createGrantForApp:(NSString*)appID accountID:(NSString*)accountID permissions:(NSDictionary*)permissions keyPair:(NSDictionary*)keyPair block:(void (^)(NSDictionary* info, NSError* error))callbackBlock {
    
    NSString *url = [[[[[self.baseURL
        stringByAppendingString: @"/apps/"] stringByAppendingString:appID]
        stringByAppendingString: @"/"] stringByAppendingString:accountID]
        stringByAppendingString: @"/__grants"];
    NSDictionary *parameters = @{
        @"manager_token": self.managerToken,
        @"permissions": permissions,
        @"to_account_id": accountID
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
        options:(NSJSONWritingOptions) (0) error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *signature = [SLCrypto signMessage:message secretKey:keyPair[@"secretKey"]];

    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:signature forHTTPHeaderField:@"X-Slab-Signature"];
    [manager.requestSerializer setValue:keyPair[@"publicKey"] forHTTPHeaderField:@"X-Slab-PublicKey"];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

//- (NSMutableArray *)


@end
