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

    SLIdentity *two = [[SLIdentity alloc] init];
    two.publicKey = @"351b3967461959ac25770abc66f21144a4231224bff33668ba5a8e4af9b610e4";
    two.secretKey = @"40f7c9e3949600f562302adf333dfaecd656c6015f5b1e2ea3d57afd585086c9351b3967461959ac25770abc66f21144a4231224bff33668ba5a8e4af9b610e4";

    return [NSMutableArray arrayWithObjects:one, two, nil];
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
