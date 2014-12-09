//
//  SlabClient.m
//  SlabClient
//
//  Created by Simon Murtha Smith on 10/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SlabClient.h"

#import "SLCrypto.h"
#import "SLAccount.h"
#import <AFNetworking.h>

static SlabClient *client;

@implementation SlabClient


+ (SlabClient*) sharedClient {
    if (client == nil){
        client = [[SlabClient alloc] init];
    }
    
    return client;
}

+ (void) loginWithPublicKey:(NSString*)pubkey callbackURI:(NSString*)redirectURI {

    NSString *encodedPublicKey = [[pubkey stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];

    NSString *url =[[[@"home://authstart?pubkey=" stringByAppendingString:encodedPublicKey] stringByAppendingString:@"&redirect_uri="] stringByAppendingString:redirectURI];

    NSLog(@"url: %@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}




- (void) updateInBackground:(NSMutableDictionary*)object toCollection:(NSMutableDictionary*)collection {
    NSString *url = [[[[SLAccount accountFromObject:collection] URLStringForCollection:collection[@"_id"]]
                      stringByAppendingString: @"/"]
                     stringByAppendingString: object[@"_id"]];

    NSLog(@"URL: %@", url);
    [self makeRequest:@"PUT" account:[SLAccount accountFromObject:collection] url:url parameters:object callback:^(id response, NSError *error) {
        if (error) {
            NSLog(@"error %@", error);
            return;
        }
        NSLog(@"JSON: %@", response);
        object[@"_updatedAt"] = response[@"_updatedAt"];
    }];
}

- (void) saveInBackground:(NSMutableDictionary*)object toCollection:(NSMutableDictionary*)collection {
    if (object[@"_id"]) {
        [self updateInBackground:object toCollection:collection];
        return;
    }

    NSString *url = [[SLAccount accountFromObject:collection] URLStringForCollection:collection[@"_id"]];

    NSLog(@"URL: %@", url);
    [self makeRequest:@"POST" account:[SLAccount accountFromObject:collection] url:url parameters:object callback:^(id response, NSError *error) {
        if (error) return;
        NSLog(@"JSON: %@", response);
        object[@"_id"] = response[@"_id"];
        object[@"_createdAt"] = response[@"_createdAt"];
        object[@"_updatedAt"] = response[@"_updatedAt"];

    }];
}

- (void) batchUpdate:(NSArray*)objects toCollection:(NSDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock {
    if (objects == nil || objects.count == 0) {
        callbackBlock(nil, nil);
        return;
    }
    NSString *url = [[[SLAccount accountFromObject:collection] URLStringForCollection:collection[@"_id"]] stringByAppendingString:@"/__batch"];

    [self makeRequest:@"PUT" account:[SLAccount accountFromObject:collection] url:url parameters:objects callback:callbackBlock];

}

- (void) deleteInBackground:(NSDictionary*)object fromCollectionID:(NSString*)collectionID {
    NSLog(@"delete object %@", object);
    NSString *url = [[SLAccount currentAccount] URLStringForObject:object collection:collectionID];
    NSLog(@"delete url %@", url);
    [self makeRequest:@"DELETE" account:[SLAccount currentAccount] url:url parameters:nil callback:^(id response, NSError *error) {
        NSLog(@"JSON: %@", response);
    }];
}

- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSDictionary*)collection {
    NSLog(@"delete object %@", object);
    NSString *url;
    if (collection != nil) {
        url = [[SLAccount accountFromObject:collection] URLStringForObject:object collection:collection[@"_id"]];
    } else {
        url = [[SLAccount accountFromObject:object] URLStringForCollection:object[@"_id"]];
    }
    NSLog(@"delete url %@", url);
    [self makeRequest:@"DELETE" account:[SLAccount currentAccount] url:url parameters:nil callback:^(id response, NSError *error) {
        NSLog(@"JSON: %@", response);
    }];
}

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock {

    NSString *url = [[SLAccount accountFromObject:collection] URLStringForCollection:collection[@"_id"]];

    [self makeRequest:@"PUT" account:[SLAccount currentAccount] url:url parameters:collection callback:callbackBlock];
}
/*

 - (void) createGrantWithPublicKey:(NSString *)publicKey block:(void (^)(NSDictionary *, NSError *))callbackBlock {

 NSString *url = [[self URLStringForCollection:<#(NSString *)#>]
 stringByAppendingString:@"__grants"];

 NSLog(@"create grant url %@", url);

 NSDictionary *body = @{
 @"public_key": publicKey
 };
 NSError *error;
 NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body
 options:(NSJSONWritingOptions) (0) error:&error];
 NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
 NSString *signature = [SLCrypto signMessage:message secretKey:self.secretKey];

 NSLog(@"message %@, signature %@", message, signature);

 AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
 manager.requestSerializer = [AFJSONRequestSerializer serializer];
 [manager.requestSerializer setValue:signature forHTTPHeaderField:@"X-Slab-Signature"];
 [manager.requestSerializer setValue:self.publicKey forHTTPHeaderField:@"X-Slab-PublicKey"];
 [manager POST:url parameters:body success:^(AFHTTPRequestOperation *operation, id responseObject) {
 NSLog(@"JSON: %@", responseObject);
 //collection[@"_updatedAt"] = responseObject[@"_updatedAt"];
 callbackBlock(responseObject, nil);
 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
 NSLog(@"Error: %@", error);
 callbackBlock(nil, error);
 }];
 }*/

- (void) getKnownIdentities:(void (^)(NSArray *identities, NSError* error))callbackBlock {
    NSMutableArray *identities = [[NSMutableArray alloc] init];
    NSString *url =[[[SLAccount currentAccount] getBaseUrl] stringByAppendingString:@"/identities"];
    [self makeRequest:@"GET" account:[SLAccount currentAccount] url:url parameters:nil callback:^(id response, NSError *error) {
        if (error != nil) {
            callbackBlock(nil, error);
        }
        for (id publicKey in response) {
            NSMutableDictionary *identity = [NSMutableDictionary dictionaryWithDictionary:response[publicKey]];
            identity[@"_id"] = publicKey;
            [identities addObject:identity];
        }

        callbackBlock(identities, error);
    }];
}

- (void) getIdentities:(NSArray*)publicKeys block:(void (^)(NSArray *identities, NSError* error))callbackBlock {
    NSMutableArray *identities = [[NSMutableArray alloc] init];
    NSString *publicKeysString = @"";
    for (int i = 0; i < publicKeys.count; i++) {
        publicKeysString = [publicKeysString stringByAppendingString:publicKeys[i]];
        if (i < publicKeys.count - 1) {
            publicKeysString = [publicKeysString stringByAppendingString:@","];
        }
    }

    NSString *url =[NSString stringWithFormat:@"%@/identities/%@", [[SLAccount currentAccount] getBaseUrl], publicKeysString];
    NSLog(@"GET identities url %@", url);

    [self makeRequest:@"GET" account:[SLAccount currentAccount] url:url parameters:nil callback:^(id response, NSError *error) {
        if (error != nil) {
            callbackBlock(nil, error);
        }
        for (id publicKey in response) {
            NSMutableDictionary *identity = [NSMutableDictionary dictionaryWithDictionary:response[publicKey]];
            identity[@"_id"] = publicKey;
            [identities addObject:identity];
        }

        callbackBlock(identities, error);
    }];
}

- (void) getTemporaryIdentities:(NSArray*)tokens block:(void (^)(NSArray *identities, NSError* error))callbackBlock {
    if (tokens == nil || tokens.count < 1) {
        return callbackBlock(nil, nil);
    }
    NSMutableArray *identities = [[NSMutableArray alloc] init];
    NSString *tokensString = @"";
    for (int i = 0; i < tokens.count; i++) {
        tokensString = [tokensString stringByAppendingString:tokens[i]];
        if (i < tokens.count - 1) {
            tokensString = [tokensString stringByAppendingString:@","];
        }
    }

    NSString *url =[NSString stringWithFormat:@"%@/identities/__temp/%@", [[SLAccount currentAccount] getBaseUrl], tokensString];
    NSLog(@"GET identities url %@", url);

    [self makeRequest:@"GET" account:[SLAccount currentAccount] url:url parameters:nil callback:^(id response, NSError *error) {
        if (error != nil) {
            callbackBlock(nil, error);
        }
        for (id token in response) {
            NSMutableDictionary *identity = [NSMutableDictionary dictionaryWithDictionary:response[token]];
            identity[@"_id"] = token;
            [identities addObject:identity];
        }

        callbackBlock(identities, error);
    }];
}


- (void) createCollectionWithAttributes:(NSMutableDictionary*)attributes block:(void (^)(NSDictionary* collection, NSError* error))callbackBlock {
    [self makeRequest:@"POST" account:[SLAccount currentAccount] url:[[SLAccount currentAccount] URLStringForAccount] parameters:@{@"attributes": attributes} callback:^(id response, NSError *error) {
        NSLog(@"response %@", response);
        attributes[@"_id"] = response[@"_id"];
        attributes[@"_createdAt"] = response[@"_createdAt"];
        attributes[@"_updatedAt"] = response[@"_updatedAt"];
        callbackBlock(response, nil);
    }];
}


- (void) findInBackground:(SLQuery*)query account:(SLAccount *)account block:(void (^)(NSMutableArray *objects, NSError* error))callbackBlock {
    NSString *url;

    if (!query.collections) {
        url = [account URLStringForCollection:query.collectionName];
    } else {
        url = [account URLStringForAccount];
    }

    NSLog(@"findInBackground URL: %@", url);

    NSString *filterString = [query filterString];

    NSDictionary *parameters = nil;

    if (filterString) {
        parameters = @{@"filter": filterString};
    }

    [self makeRequest:@"GET" account:[SLAccount currentAccount] url:url parameters:parameters callback:^(NSArray *response, NSError *error) {
        if (error) {
            callbackBlock(response, error);
            return;
        }
        [self fillData:response withAccount:account block:callbackBlock];
    }];
}

- (void) fillData:(NSArray*)objects withAccount:(SLAccount *)account block:(void (^)(NSMutableArray *, NSError* error))callbackBlock {
    NSMutableArray *followedData = [[NSMutableArray alloc] init];
    [self fillData:objects fromIndex:0 withAccount:account intoArray:followedData block:^(NSError *error) {
        callbackBlock(followedData, error);
    }];
}

- (void) fillData:(NSArray*)objects fromIndex:(unsigned long)index withAccount:(SLAccount *)account intoArray:(NSMutableArray *)destination block:(void (^)(NSError* error))callbackBlock {
    if (index == [objects count]) {
        return callbackBlock(nil);
    }

    NSDictionary *list = objects[index];

    if (list[@"pointer"] == nil) {
        [destination addObject:list];
        [self fillData:objects fromIndex:(index + 1) withAccount:account intoArray:destination block:callbackBlock];
    } else {
        NSString *baseUrl = list[@"pointer"][@"base_url"];
        NSString *accountID = list[@"pointer"][@"account_id"];
        NSDictionary *keyPair = @{
            @"publicKey": [[SLAccount currentAccount] getPublicKey],
            @"secretKey": [[SLAccount currentAccount] getSecretKey]
        };
        SLAccount *account = [SLAccount accountWithBaseUrl:baseUrl appID:@"myTodos" accountID:accountID keyPair:keyPair];

        SLQuery *query = [SLQuery collectionQuery];

        [query whereKey:@"_id" equalTo:list[@"pointer"][@"collection_id"]];
        [[SlabClient sharedClient] findInBackground:query account:account block:^(NSArray *foundObjects, NSError *error) {
            if (error != nil) {
                return callbackBlock(error);
            }
            if (foundObjects.count != 1) {
                NSLog(@"didn't find an object when following pointer: %@", list);
                [self fillData:objects fromIndex:(index + 1) withAccount:account intoArray:destination block:callbackBlock];
                return;
            }

            NSMutableDictionary *fullList = (NSMutableDictionary*)foundObjects[0];
            fullList[@"revPointer"] = list;
            [destination addObject:fullList];
            
            // phew!
            [self fillData:objects fromIndex:(index + 1) withAccount:account intoArray:destination block:callbackBlock];
        }];
    }
}


- (void) createTemporaryIdentity:(NSDictionary*)parameters block:(void (^)(NSString *token, NSError* error))callbackBlock {
    [self createTemporaryIdentity:parameters account:[SLAccount currentAccount] block:callbackBlock];
}

- (void) createTemporaryIdentity:(NSDictionary*)parameters account:(SLAccount *)account block:(void (^)(NSString *token, NSError* error))callbackBlock {
    NSString *url = [[account getBaseUrl] stringByAppendingString:@"/identities/__temp"];

    [self makeRequest:@"POST" account:account url:url parameters:parameters callback:^(id response, NSError *error) {
        if (error) {
            return callbackBlock(nil, error);
        }
        callbackBlock(response[@"temporary_id"], nil);
    }];
}

- (void) convertTemporaryIdentity:(NSString *)token remoteAccount:(SLAccount*)account withAppData:(NSDictionary *)appData block:(void (^)(NSError* error))callbackBlock {
    NSString *url = [[[account getBaseUrl] stringByAppendingString:@"/identities/"] stringByAppendingString:[[SLAccount currentAccount] getPublicKey]];

    NSDictionary *params = @{
        @"temporary_id": token,
        @"account_id": [[SLAccount currentAccount] getAccountID],
        @"base_url": [[SLAccount currentAccount] getBaseUrl],
        @"app_data": @{
            [[SLAccount currentAccount] getAppID]:appData
        }
    };

    NSLog(@"remove account conversion url %@, params %@", url, params);

    [self makeRequest:@"PUT" account:account url:url parameters:params callback:^(id response, NSError *error) {
        NSLog(@"response from convert %@", response);
        if (error) {
            return callbackBlock(error);
        }
        callbackBlock(nil);
    }];
}

- (void) makeRequest:(NSString*)method account:(SLAccount*)account url:(NSString*)url parameters:(id)parameters callback:(void (^)(id response, NSError* error))callbackBlock {

    method = [method uppercaseString];

    NSLog(@"%@ %@", method, url);

    // TODO: ensure method is only {GET,POST,PUT,DELETE}

    NSError *error;

    NSMutableURLRequest* request = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:url parameters:parameters error:&error];

    method = [request HTTPMethod];
    url = [[request URL] absoluteString];
    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    NSString *message = [[[[method stringByAppendingString:@"\n"] stringByAppendingString:url] stringByAppendingString:@"\n"] stringByAppendingString:body];

    NSString *signature = [SLCrypto signMessage:message secretKey:[account getSecretKey]];

//    NSLog(@"message: %@\nsignature: %@", message, signature);


    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:signature forHTTPHeaderField:@"X-Slab-Signature"];
    [manager.requestSerializer setValue:[account getPublicKey] forHTTPHeaderField:@"X-Slab-PublicKey"];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if ([method isEqualToString:@"GET"]) {
        NSLog(@"getting: %@", url);
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"POST"]) {
        NSLog(@"making POST request. \nurl: %@ \nparameters: %@", url, parameters);
        [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"made request. response object %@", responseObject);
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"PUT"]) {
        [manager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"DELETE"]) {
        [manager DELETE:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            callbackBlock(nil, error);
        }];
    }
}


@end
