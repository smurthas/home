//
//  SLQuery.m
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SLQuery.h"

@implementation SLQuery

+ (SLQuery*) objectQueryWithCollectionName:(NSString*)collectionName {
    SLQuery *query = [[SLQuery alloc] init];
    query.collectionName = collectionName;
    query.collections = NO;

    query.filters = [[NSMutableDictionary alloc] init];

    return query;
}


+ (SLQuery*) collectionQuery {
    SLQuery *query = [[SLQuery alloc] init];
    query.collections = YES;

    query.filters = [[NSMutableDictionary alloc] init];

    return query;
}

- (void) getObjectInBackgroundWithId:(NSString*)_id {

}

- (void) whereKey:(NSString*)whereKey equalTo:(id)equalTo {
    NSLog(@"whereKey %@", whereKey);
    NSLog(@"equalTo %@", equalTo);
    self.filters[whereKey] = equalTo;
    //    NSDictionary *filter = @{whereKey: equalTo};
    //    [self.filters addObject:filter];
}

- (NSString*) filterString {
    if (!self.filters || self.filters.count < 1) return nil;

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self.filters options:0 error:nil];
    return [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
}


@end
