//
//  HMQuery.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "HMQuery.h"
#import "HMAccount.h"


#import <AFNetworking.h>
#import <SBJson4.h>


@interface HMQuery ()


@end

@implementation HMQuery

+ (HMQuery*) objectQueryWithCollectionName:(NSString*)collectionName {
    HMQuery *query = [[HMQuery alloc] init];
    query.collectionName = collectionName;
    query.collections = NO;
    
    query.filters = [[NSMutableDictionary alloc] init];
    
    return query;
}


+ (HMQuery*) collectionQuery {
    HMQuery *query = [[HMQuery alloc] init];
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
    
    SBJson4Writer *writer = [[SBJson4Writer alloc] init];
    NSString* string = [writer stringWithObject:self.filters];
    
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}



@end
