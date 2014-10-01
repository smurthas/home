//
//  HMApp.m
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMBase.h"

#import <libsodium-ios/sodium.h>

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

- (void)createAccountAndApp:(NSString*)appID block:(void (^)(NSDictionary* info, NSError* error))callbackBlock {
    
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

- (void)createGrantForApp:(NSString*)appID accountID:(NSString*)accountID permissions:(NSDictionary*)permissions block:(void (^)(NSDictionary* info, NSError* error))callbackBlock {
    
    NSString *url = [[[[[self.baseURL
        stringByAppendingString: @"/apps/"] stringByAppendingString:appID]
        stringByAppendingString: @"/"] stringByAppendingString:accountID]
        stringByAppendingString: @"/__grants"];
    NSDictionary *parameters = @{
        @"manager_token": self.managerToken,
        @"permissions": permissions,
        @"to_account_id": accountID
    };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


+ (NSString *)stringWithHexFromData:(NSData *)data
{
    NSString *result = [[data description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    return result;
}

+ (NSData *)dataFromStringWithHex:(NSString *)string {
    NSMutableData *data = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([string length] / 2); i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    
    return data;
}

+ (NSDictionary *)generateKeyPair {
    unsigned char sk[crypto_sign_SECRETKEYBYTES];
    unsigned char pk[crypto_sign_PUBLICKEYBYTES];
    
    crypto_sign_keypair(pk, sk);
    
    NSData *pkData = [NSData dataWithBytes:pk length:crypto_sign_PUBLICKEYBYTES];
    NSData *skData = [NSData dataWithBytes:sk length:crypto_sign_SECRETKEYBYTES];
    
    return @{
        @"publicKey": [HMBase stringWithHexFromData:pkData],
        @"secretKey": [HMBase stringWithHexFromData:skData],
    };
}

+ (NSString *)signMessage:(NSString*)message secretKey:(NSString *)sSecretKey {
    NSLog(@"message %@, length %lu", message, (unsigned long)[message length]);
    NSData *dSecretKey = [HMBase dataFromStringWithHex:sSecretKey];
    
    NSUInteger size = [dSecretKey length] / sizeof(unsigned char);
    unsigned char* secretKey = (unsigned char*) [dSecretKey bytes];
    
    unsigned char *m = [message cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long long mlen = [message length];
    
    NSLog(@"m %s", m);
    
    // these will be filled by crypto_sign
    unsigned char sm[crypto_sign_BYTES + mlen];
    unsigned long long smlen;
    crypto_sign(sm, &smlen, m, mlen, secretKey);
    
    NSData* dSign = [NSData dataWithBytes:sm length:sizeof(unsigned char) * (smlen - mlen)];
    return [HMBase stringWithHexFromData:dSign];
}

+ (BOOL)verifyMessage:(NSString *)signature message:(NSString*)message publicKey:(NSString *)publicKey {
    NSData *dPublicKey = [HMBase dataFromStringWithHex:publicKey];
    NSInteger size = [dPublicKey length] / sizeof(unsigned char);
    unsigned char* pk = (unsigned char*) [dPublicKey bytes];
    
    unsigned char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *dMessage = [NSData dataWithBytes:cMessage length:[message length]];
    
    NSLog(@"dMessage %@", dMessage);
    
    NSString *sealedMessage = [signature stringByAppendingString:[HMBase stringWithHexFromData:dMessage]];
    NSLog(@"sealedMessage %@", sealedMessage);
    NSData *dSealedMessage = [HMBase dataFromStringWithHex:sealedMessage];
    size = [dSealedMessage length] / sizeof(unsigned char);
    
    unsigned char* sm = (unsigned char*) [dSealedMessage bytes];
    unsigned long long smlen = size;
    
    // these will be filled by crypto_sign_open
    unsigned char m[smlen];
    unsigned long long mlen;
    
    int result = crypto_sign_open(m, &mlen, sm, smlen, pk);
    
    // 0 is success
    if (result != 0) return NO;
    return YES;
//    NSLog(@"m %s, len %llu", m, mlen);
//    
//    size = mlen;
//    NSData* dMessage = [NSData dataWithBytes:m length:sizeof(unsigned char) * mlen];
//    NSLog(@"dMessage %@", dMessage);
//    return [NSString stringWithUTF8String:[dMessage bytes]];
//    return [[NSString alloc] initWithData:dMessage encoding:NSUTF8StringEncoding];
}


@end
