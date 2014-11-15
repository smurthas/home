//
//  SLIdentity.h
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLIdentity : NSObject

@property NSString* publicKey;
@property NSString* secretKey;

+ (NSMutableArray*)getIdentities;
+ (SLIdentity*) identityForPublicKey:(NSString*)publicKey;
+ (SLIdentity*) identityWithKeyPair:(NSDictionary*)keyPair;

- (NSDictionary*)keyPair;

@end
