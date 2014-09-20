//
//  HMApp.h
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMApp : NSObject

+ (void)generateAccessToken:managerToken withPublicKey:(NSString*)publicKey block:(void (^)(NSString* token, NSError* error))callbackBlock;

@end
