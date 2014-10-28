//
//  HMAccount.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMAccount.h"

#import "HMQuery.h"

#import <SlabClient/SLCrypto.h>
#import <AFNetworking.h>


static HMAccount *currentAccount;


@interface HMAccount ()

@property NSString* token;
@property NSString* secretKey;
@property NSString* publicKey;
@property NSString* accountID;
@property NSString* appID;
@property NSString* baseUrl;


@end


@implementation HMAccount

+ (HMAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID keyPair:(NSDictionary*)keyPair {
    HMAccount* account = [[HMAccount alloc] init];
    account.baseUrl = baseUrl;
    account.accountID = accountID;
    account.secretKey = keyPair[@"secretKey"];
    account.publicKey = keyPair[@"publicKey"];
    account.appID = appID;
    
    return account;
}

+ (HMAccount*) accountFromObject:(NSDictionary*)object {

    NSString *baseUrl = object[@"_host"];
    NSString *accountID = object[@"_accountID"];
    NSDictionary *usedKeyPair = @{
        @"publicKey": [[HMAccount currentAccount] getPublicKey],
        @"secretKey": [[HMAccount currentAccount] getSecretKey]
    };

    return [HMAccount accountWithBaseUrl:baseUrl appID:[HMAccount currentAccount].appID accountID:accountID keyPair:usedKeyPair];
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

+ (void) becomeWithKeyPair:(NSDictionary*)keyPair accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock {
    currentAccount = [[HMAccount alloc] init];
    currentAccount.publicKey = keyPair[@"publicKey"];
    currentAccount.secretKey = keyPair[@"secretKey"];
    currentAccount.accountID = accountID;
    currentAccount.appID = appID;
    currentAccount.baseUrl = baseURL;
    callbackBlock(YES, nil);
}

+ (void) become:(HMAccount *)anotherAccount {
    currentAccount = anotherAccount;
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

- (NSString *) getSecretKey {
    return self.secretKey;
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
    return [[[[[[self.baseUrl
        stringByAppendingString:@"/apps/"]
        stringByAppendingString:self.appID]
        stringByAppendingString:@"/"]
        stringByAppendingString:self.accountID]
        stringByAppendingString:@"/"]
        stringByAppendingString: collection];
}

- (NSString*) URLStringForObject:(NSDictionary*)object collection:(NSString*)collection {
    return [[[self URLStringForCollection:collection]
        stringByAppendingString:@"/"]
        stringByAppendingString:object[@"_id"]];
}


- (void) updateInBackground:(NSMutableDictionary*)object toCollection:(NSString*)collection {
    NSString *url = [[[self URLStringForCollection:collection]
        stringByAppendingString: @"/"]
        stringByAppendingString: object[@"_id"]];

    [self makeRequest:@"PUT" url:url parameters:object callback:^(id response, NSError *error) {
        if (error) {
            NSLog(@"error %@", error);
            return;
        }
        NSLog(@"JSON: %@", response);
        object[@"_updatedAt"] = response[@"_updatedAt"];
    }];
}

- (void) saveInBackground:(NSMutableDictionary*)object toCollection:(NSString*)collection {
    if (object[@"_id"]) {
        [self updateInBackground:object toCollection:collection];
        return;
    }
    
    NSString *url = [self URLStringForCollection:collection];

    [self makeRequest:@"POST" url:url parameters:object callback:^(id response, NSError *error) {
        if (error) return;
        NSLog(@"JSON: %@", response);
        object[@"_id"] = response[@"_id"];
        object[@"_createdAt"] = response[@"_createdAt"];
        object[@"_updatedAt"] = response[@"_updatedAt"];

    }];
}

- (void) batchUpdate:(NSArray*)objects toCollection:(NSString*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock {

    NSString *url = [[self URLStringForCollection:collection] stringByAppendingString:@"/__batch"];

    [self makeRequest:@"PUT" url:url parameters:objects callback:callbackBlock];

}

- (void) deleteInBackground:(NSDictionary*)object fromCollection:(NSString*)collection {
    NSString *url = [self URLStringForObject:object collection:collection];
    NSLog(@"delete url %@", url);
    [self makeRequest:@"DELETE" url:url parameters:nil callback:^(id response, NSError *error) {
        NSLog(@"JSON: %@", response);
    }];
}

- (void) saveCollection:(NSMutableDictionary*)collection block:(void (^)(NSDictionary *, NSError *))callbackBlock {
    
    NSString *url = [self URLStringForCollection:collection[@"_id"]];

    [self makeRequest:@"PUT" url:url parameters:collection callback:callbackBlock];
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
    NSString *url =[[self getBaseUrl] stringByAppendingString:@"/identities"];
    [self makeRequest:@"GET" url:url parameters:nil callback:^(id response, NSError *error) {
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

    NSString *url =[NSString stringWithFormat:@"%@/identities/%@", [self getBaseUrl], publicKeysString];
    NSLog(@"GET identities url %@", url);

    [self makeRequest:@"GET" url:url parameters:nil callback:^(id response, NSError *error) {
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

    NSString *url =[NSString stringWithFormat:@"%@/identities/__temp/%@", [self getBaseUrl], tokensString];
    NSLog(@"GET identities url %@", url);

    [self makeRequest:@"GET" url:url parameters:nil callback:^(id response, NSError *error) {
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
    [self makeRequest:@"POST" url:[self URLStringForAccount] parameters:@{@"attributes": attributes} callback:^(id response, NSError *error) {
        NSLog(@"response %@", response);
        attributes[@"_id"] = response[@"_id"];
        attributes[@"_createdAt"] = response[@"_createdAt"];
        attributes[@"_updatedAt"] = response[@"_updatedAt"];
        callbackBlock(response, nil);
    }];
}


- (void) findInBackground:(HMQuery*)query block:(void (^)(NSArray *objects, NSError* error))callbackBlock {
    NSString *url;
    
    if (!query.collections) {
        url = [self URLStringForCollection:query.collectionName];
    } else {
        url = [self URLStringForAccount];
    }

    NSLog(@"findInBackground URL: %@", url);
    
    NSString *filterString = [query filterString];

    NSDictionary *parameters = nil;
    
    if (filterString) {
        parameters = @{@"filter": filterString};
    }

    [self makeRequest:@"GET" url:url parameters:parameters callback:callbackBlock];
}

- (void) createTemporaryIdentity:(NSDictionary*)parameters block:(void (^)(NSString *token, NSError* error))callbackBlock {
    NSString *url = [self.baseUrl stringByAppendingString:@"/identities/__temp"];

    [self makeRequest:@"POST" url:url parameters:parameters callback:^(id response, NSError *error) {
        if (error) {
            return callbackBlock(nil, error);
        }
        callbackBlock(response[@"temporary_id"], nil);
    }];
}

- (void) convertTemporaryIdentity:(NSString *)token block:(void (^)(NSError* error))callbackBlock {
    NSString *url = [[self.baseUrl stringByAppendingString:@"/identities/"] stringByAppendingString:self.publicKey];

    [self makeRequest:@"PUT" url:url parameters:@{@"temporary_id": token} callback:^(id response, NSError *error) {
        if (error) {
            return callbackBlock(error);
        }
        callbackBlock(nil);
    }];
}

- (void) makeRequest:(NSString*)method url:(NSString*)url parameters:(id)parameters callback:(void (^)(id response, NSError* error))callbackBlock {

    method = [method uppercaseString];

    NSLog(@"method %@", method);

    // TODO: ensure method is only {GET,POST,PUT,DELETE}

    NSError *error;

    NSMutableURLRequest* request = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:url parameters:parameters error:&error];

    method = [request HTTPMethod];
    url = [[request URL] absoluteString];
    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    NSString *message = [[[[method stringByAppendingString:@"\n"] stringByAppendingString:url] stringByAppendingString:@"\n"] stringByAppendingString:body];

    NSString *signature = [SLCrypto signMessage:message secretKey:self.secretKey];

    NSLog(@"message %@, signature %@", message, signature);


    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:signature forHTTPHeaderField:@"X-Slab-Signature"];
    [manager.requestSerializer setValue:self.publicKey forHTTPHeaderField:@"X-Slab-PublicKey"];

    if ([method isEqualToString:@"GET"]) {
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"POST"]) {
        NSLog(@"making POST request. \nurl: %@ \nparameters: %@", url, parameters);
        [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"made request. response object %@", responseObject);
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"PUT"]) {
        [manager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            callbackBlock(nil, error);
        }];
    } else if ([method isEqualToString:@"DELETE"]) {
        [manager DELETE:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            callbackBlock(responseObject, nil);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            callbackBlock(nil, error);
        }];
    }
}


@end
