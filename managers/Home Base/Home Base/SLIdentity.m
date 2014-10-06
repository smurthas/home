//
//  SLIdentity.m
//  Home Base
//
//  Created by Simon Murtha Smith on 10/2/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SLIdentity.h"

@implementation SLIdentity

+ (NSMutableArray*)getIdentities {
    SLIdentity *one = [[SLIdentity alloc] init];
    one.publicKey = @"3991d233de34b66ac1020304336e66148a1a9504c11cec42e562b355253a6afe";
    one.secretKey = @"e4923aba31c95f964934b07a0c6c9b2c03001b7cb9cc7b539c27307f42b193453991d233de34b66ac1020304336e66148a1a9504c11cec42e562b355253a6afe";

    return [NSMutableArray arrayWithObjects:one, nil];
}

+ (SLIdentity*) identityForPublicKey:(NSString*)publicKey {
    for (SLIdentity *identity in [SLIdentity getIdentities]) {
        if (identity.publicKey == publicKey) {
            return identity;
        }
    }

    return nil;
}

+ (SLIdentity*) identityWithKeyPair:(NSDictionary*)keyPair {
    SLIdentity *identity = [[SLIdentity alloc] init];
    identity.publicKey = keyPair[@"publicKey"];
    identity.secretKey = keyPair[@"secretKey"];

    return identity;
}

- (NSDictionary*)keyPair {
    return @{
        @"publicKey": self.publicKey,
        @"secretKey": self.secretKey
    };
}

@end
