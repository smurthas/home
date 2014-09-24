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

@property NSString *className;
@property NSMutableDictionary *filters;

@end

@implementation HMQuery

+ (HMQuery*) queryWithClassName:(NSString*)className {
    HMQuery *query = [[HMQuery alloc] init];
    query.className = className;
    
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

- (void) findObjectsInBackgroundWithBlock:(void (^)(NSArray *object, NSError* error))callbackBlock {
    NSString *token = [[HMAccount currentAccount] getToken];
    NSString *url = [[[[HMAccount currentAccount] URLStringForCollection:self.className ]
                      stringByAppendingString:@"?token="]
                     stringByAppendingString:token];
    
    NSString *filterString = [self filterString];
    
    NSLog(@"url1 %@", url);
    
    if (filterString) {
        url = [[url stringByAppendingString:@"&filter="]
            stringByAppendingString:filterString];
    }
    
    
    NSLog(@"url2 %@", url);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions: NSJSONReadingMutableContainers];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        callbackBlock(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callbackBlock(nil, error);
    }];
}


@end
