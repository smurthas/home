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

+ (void)generateAccessToken:managerToken withPublicKey:(NSString*)publicKey block:(void (^)(NSString* token, NSError* error))callbackBlock {

    NSString *url = @"http://localhost:2570/auth/tokens";
    NSDictionary *parameters = @{@"manager_token": managerToken, @"pub_key": publicKey};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject[@"token"], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


@end
