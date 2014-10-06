//
//  SLCrypto.m
//  Home Base
//
//  Created by Simon Murtha Smith on 10/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SLCrypto.h"

#import <libsodium-ios/sodium.h>

@implementation SLCrypto


+ (NSString *)stringWithHexFromData:(NSData *)data {
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
             @"publicKey": [SLCrypto stringWithHexFromData:pkData],
             @"secretKey": [SLCrypto stringWithHexFromData:skData],
             };
}

+ (NSString *)signMessage:(NSString*)message secretKey:(NSString *)sSecretKey {
    NSData *dSecretKey = [SLCrypto dataFromStringWithHex:sSecretKey];

    unsigned char *secretKey = (unsigned char*) [dSecretKey bytes];

    unsigned char *m = (unsigned char*) [message cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long long mlen = [message length];

    // these will be filled by crypto_sign
    unsigned char sm[crypto_sign_BYTES + mlen];
    unsigned long long smlen;
    crypto_sign(sm, &smlen, m, mlen, secretKey);

    NSData* dSign = [NSData dataWithBytes:sm length:sizeof(unsigned char) * (smlen - mlen)];
    return [SLCrypto stringWithHexFromData:dSign];
}

+ (BOOL)verifyMessage:(NSString *)signature message:(NSString*)message publicKey:(NSString *)publicKey {
    NSData *dPublicKey = [SLCrypto dataFromStringWithHex:publicKey];
    NSInteger size = [dPublicKey length] / sizeof(unsigned char);
    unsigned char* pk = (unsigned char*) [dPublicKey bytes];

    unsigned char *cMessage = (unsigned char*) [message cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *dMessage = [NSData dataWithBytes:cMessage length:[message length]];

    NSString *sealedMessage = [signature stringByAppendingString:[SLCrypto stringWithHexFromData:dMessage]];
    NSData *dSealedMessage = [SLCrypto dataFromStringWithHex:sealedMessage];
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
}


@end
