//
//  SLAccount.m
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SLAccount.h"


static SLAccount *currentAccount;

@interface SLAccount ()

@property NSString* secretKey;
@property NSString* publicKey;
@property NSString* accountID;
@property NSString* appID;
@property NSString* baseUrl;

@end

@implementation SLAccount


+ (SLAccount*) accountWithBaseUrl:(NSString*)baseUrl appID:(NSString*)appID accountID:(NSString*)accountID keyPair:(NSDictionary*)keyPair {
    SLAccount* account = [[SLAccount alloc] init];
    account.baseUrl = baseUrl;
    account.accountID = accountID;
    account.secretKey = keyPair[@"secretKey"];
    account.publicKey = keyPair[@"publicKey"];
    account.appID = appID;

    return account;
}

+ (SLAccount*) accountFromObject:(NSDictionary*)object {

    NSString *baseUrl = object[@"_host"];
    NSString *accountID = object[@"_accountID"];
    NSDictionary *usedKeyPair = @{
        @"publicKey": currentAccount.publicKey,
        @"secretKey": currentAccount.secretKey
    };

    return [SLAccount accountWithBaseUrl:baseUrl appID:SLAccount.currentAccount.appID accountID:accountID keyPair:usedKeyPair];
}


+ (void) becomeWithKeyPair:(NSDictionary*)keyPair accountID:(NSString*)accountID appID:(NSString*)appID baseURL:(NSString*)baseURL block:(void (^)(BOOL succeeded, NSError* error))callbackBlock {
    currentAccount = [[SLAccount alloc] init];
    currentAccount.publicKey = keyPair[@"publicKey"];
    currentAccount.secretKey = keyPair[@"secretKey"];
    currentAccount.accountID = accountID;
    currentAccount.appID = appID;
    currentAccount.baseUrl = baseURL;
    callbackBlock(YES, nil);
}

+ (void) become:(SLAccount *)anotherAccount {
    currentAccount = anotherAccount;
}


+ (SLAccount*) currentAccount {
    return currentAccount;
}



- (NSString*) URLStringForAccount {
    return [[[[[self.baseUrl
                stringByAppendingString:@"/apps/"]
               stringByAppendingString:self.appID]
              stringByAppendingString:@"/"]
             stringByAppendingString:self.accountID]
            stringByAppendingString:@"/"];
}

- (NSString*) URLStringForCollection:(NSString*)collection{
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


//
//
//- (NSString *) getAccountID {
//    return self.accountID;
//}
//
- (NSString *) getBaseUrl {
    return self.baseUrl;
}

- (NSString *) getPublicKey {
    return self.publicKey;
}

- (NSString *) getSecretKey {
    return self.secretKey;
}


@end
