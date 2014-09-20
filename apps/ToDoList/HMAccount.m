//
//  HMAccount.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMAccount.h"

#import <AFNetworking.h>


static HMAccount *currentAccount;


@interface HMAccount ()

@property NSString* token;
@property NSString* baseUrl;

@end


@implementation HMAccount

+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI {

    NSString *encodedPublicKey = [[pubkey stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    NSString *url =[[[@"home://authstart?pubkey=" stringByAppendingString:encodedPublicKey] stringByAppendingString:@"&redirect_uri="] stringByAppendingString:redirectURI];
    
    NSLog(@"url: %@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (HMAccount*) currentAccount {
    return currentAccount;
}

+ (void) becomeWithToken:(NSString*)token baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock {
    currentAccount = [[HMAccount alloc] init];
    currentAccount.token = token;
    currentAccount.baseUrl = baseURL;
    callbackBlock(YES, nil);
}

- (NSString *) getToken {
    return self.token;
}

- (NSString *) getBaseUrl {
    return self.baseUrl;
}

- (void) updateInBackground:(NSMutableDictionary*)object toCollection:(NSString*)collection {
    NSString *url = [[[[[[self.baseUrl
        stringByAppendingString:@"/apps/"]
        stringByAppendingString: collection]
        stringByAppendingString:@"/"]
        stringByAppendingString: object[@"_id"]]
        stringByAppendingString:@"?token="]
        stringByAppendingString:self.token];
    
    NSLog(@"update url %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager PUT:url parameters:object success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        object[@"_updatedAt"] = responseObject[@"_updatedAt"];
        //callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        //callbackBlock(nil, error);
    }];
}

- (void) saveInBackground:(NSMutableDictionary*)object toCollection:(NSString*)collection {
    if (object[@"_id"]) {
        [self updateInBackground:object toCollection:collection];
        return;
    }
    
    NSString *url = [[[[self.baseUrl
                        stringByAppendingString:@"/apps/"]
                       stringByAppendingString: collection]
                      stringByAppendingString:@"?token="]
                     stringByAppendingString:self.token];
    
    NSLog(@"url %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:object success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        object[@"_id"] = responseObject[@"_id"];
        object[@"_createdAt"] = responseObject[@"_createdAt"];
        object[@"_updatedAt"] = responseObject[@"_updatedAt"];
        //callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        //callbackBlock(nil, error);
    }];
}

- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection {
    NSString *url = [[[[[[self.baseUrl
                          stringByAppendingString:@"/apps/"]
                         stringByAppendingString: collection]
                        stringByAppendingString:@"/"]
                       stringByAppendingString: object[@"_id"]]
                      stringByAppendingString:@"?token="]
                     stringByAppendingString:self.token];
    
    NSLog(@"update url %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        //callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        //callbackBlock(nil, error);
    }];
}

@end
