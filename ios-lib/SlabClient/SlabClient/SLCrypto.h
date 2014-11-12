//
//  SLCrypto.h
//  Home Base
//
//  Created by Simon Murtha Smith on 10/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLCrypto : NSObject

+ (NSString *)stringWithHexFromData:(NSData *)data;
+ (NSData *)dataFromStringWithHex:(NSString *)string;

+ (NSDictionary *)generateKeyPair;
+ (NSString *)signMessage:(NSString*)message secretKey:(NSString*)secretKey;
+ (BOOL)verifyMessage:(NSString *)signature message:(NSString*)message publicKey:(NSString *)publicKey;


@end
