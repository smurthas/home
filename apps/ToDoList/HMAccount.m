//
//  HMAccount.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMAccount.h"

#import "HMQuery.h"

#import <AFNetworking.h>


static HMAccount *currentAccount;


@interface HMAccount ()

@property NSString* token;
@property NSString* accountID;
@property NSString* appID;
@property NSString* baseUrl;
@property NSString* publicKey;

@end


@implementation HMAccount

+ (HMAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID token:(NSString*)token {
    HMAccount* account = [[HMAccount alloc] init];
    account.baseUrl = baseUrl;
    account.accountID = accountID;
    account.token = token;
    account.appID = appID;
    
    return account;
}

+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI {

    NSString *encodedPublicKey = [[pubkey stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    NSString *url =[[[@"home://authstart?pubkey=" stringByAppendingString:encodedPublicKey] stringByAppendingString:@"&redirect_uri="] stringByAppendingString:redirectURI];
    
    NSLog(@"url: %@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

+ (HMAccount*) currentAccount {
    return currentAccount;
}

+ (void) becomeWithToken:(NSString*)token accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock {
    currentAccount = [[HMAccount alloc] init];
    currentAccount.token = token;
    currentAccount.accountID = accountID;
    currentAccount.appID = appID;
    currentAccount.baseUrl = baseURL;
    callbackBlock(YES, nil);
}

- (NSString *) getToken {
    return self.token;
}

- (NSString *) getAccountID {
    return self.accountID;
}

- (NSString *) getBaseUrl {
    return self.baseUrl;
}

- (NSString *) getPublicKey {
    return self.publicKey;
}


- (NSString*) URLStringForAccount {
    return [[[[[self.baseUrl
        stringByAppendingString:@"/apps/"]
        stringByAppendingString:self.appID]
        stringByAppendingString:@"/"]
        stringByAppendingString:self.accountID]
        stringByAppendingString:@"/"];
}

- (NSString*) URLStringForCollection:(NSString*)collection {
    return [[[[[[[self.baseUrl
        stringByAppendingString:@"/apps/"]
        stringByAppendingString:self.appID]
        stringByAppendingString:@"/"]
        stringByAppendingString:self.accountID]
        stringByAppendingString:@"/"]
        stringByAppendingString: collection]
        stringByAppendingString:@"/"];
}

- (void) updateInBackground:(NSMutableDictionary*)object toCollection:(NSString*)collection {
    NSString *url = [[[[self URLStringForCollection:collection]
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
    
    NSString *url = [[[self URLStringForCollection:collection]
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

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock {
    
    NSString *url = [[[self URLStringForCollection:collection[@"_id"]]
                      stringByAppendingString:@"?token="]
                     stringByAppendingString:self.token];
    
    NSLog(@"update collection url %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager PUT:url parameters:collection success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        //collection[@"_updatedAt"] = responseObject[@"_updatedAt"];
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callbackBlock(nil, error);
    }];
}


- (void) createGrantWithAccountID:(NSString *)toAccountID block:(void (^)(NSDictionary *, NSError *))callbackBlock {
    
    NSString *url = [[[self URLStringForAccount]
        stringByAppendingString:@"__grants/?token="]
        stringByAppendingString:self.token];
    
    NSLog(@"create grant url %@", url);
    
    NSDictionary *body = @{
        @"to_account_id": toAccountID
    };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:body success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        //collection[@"_updatedAt"] = responseObject[@"_updatedAt"];
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callbackBlock(nil, error);
    }];
}

- (void)sendGrant:(NSDictionary*)grant toAccount:(HMAccount*)toAccount forResource:(NSDictionary*)resource {
    
}


- (void) createCollectionWithAttributes:(NSMutableDictionary*)attributes block:(void (^)(NSDictionary* collection, NSError* error))callbackBlock {
    
    NSString *url = [[[self URLStringForAccount]
                      stringByAppendingString:@"?token="]
                     stringByAppendingString:self.token];
    
    NSLog(@"create collection url %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:@{@"attributes": attributes} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        attributes[@"_id"] = responseObject[@"_id"];
        attributes[@"_createdAt"] = responseObject[@"_createdAt"];
        attributes[@"_updatedAt"] = responseObject[@"_updatedAt"];
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callbackBlock(nil, error);
    }];
}


- (void) findInBackground:(HMQuery*)query block:(void (^)(NSArray *objects, NSError* error))callbackBlock {
    NSString *url;
    
    if (!query.collections) {
        url = [[[self URLStringForCollection:query.collectionName]
                stringByAppendingString:@"?token="]
               stringByAppendingString:self.token];
    } else {
        url = [[[[HMAccount currentAccount] URLStringForAccount]
                stringByAppendingString:@"?token="]
               stringByAppendingString:self.token];
        
    }
    
    NSString *filterString = [query filterString];
    
    NSLog(@"url1 %@", url);
    
    if (filterString) {
        url = [[url stringByAppendingString:@"&filter="]
               stringByAppendingString:filterString];
    }
    
    
    NSLog(@"url2 %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callbackBlock(nil, error);
    }];
}


@end
