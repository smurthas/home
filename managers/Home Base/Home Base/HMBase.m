//
//  HMApp.m
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMBase.h"

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
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)createAccountAndGrantForApp:(NSString*)appID block:(void (^)(NSDictionary* info, NSError* error))callbackBlock {
    NSString *url = [[self.baseURL stringByAppendingString: @"/apps/"] stringByAppendingString:appID];
    NSDictionary *parameters = @{@"manager_token": self.managerToken};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)createGrantForApp:(NSString*)appID accountID:(NSString*)accountID block:(void (^)(NSDictionary* info, NSError* error))callbackBlock {
    
    NSString *url = [[[[[self.baseURL
        stringByAppendingString: @"/apps/"] stringByAppendingString:appID]
        stringByAppendingString: @"/"] stringByAppendingString:accountID]
        stringByAppendingString: @"/__grants"];
    NSDictionary *parameters = @{@"manager_token": self.managerToken};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


@end
