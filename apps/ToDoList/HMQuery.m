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
@property NSMutableArray *filters;

@end

@implementation HMQuery

+ (HMQuery*) queryWithClassName:(NSString*)className {
    HMQuery *query = [[HMQuery alloc] init];
    query.className = className;
    
    query.filters = [[NSMutableArray alloc] init];
    
    return query;
}

- (void) getObjectInBackgroundWithId:(NSString*)_id {
    
}

- (void) whereKey:(NSString*)whereKey equalTo:(id)equalTo {
    NSLog(@"whereKey %@", whereKey);
    NSLog(@"equalTo %@", equalTo);
    NSDictionary *filter = @{whereKey: equalTo};
    [self.filters addObject:filter];
}

- (NSString*) filterString {
    NSDictionary *filter = self.filters[0];
    
    SBJson4Writer *writer = [[SBJson4Writer alloc] init];
    NSString* string = [writer stringWithObject:filter];
    
    return [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

- (void) findObjectsInBackgroundWithBlock:(void (^)(NSArray *object, NSError* error))callbackBlock {
    NSString *token = [[HMAccount currentAccount] getToken];
    NSString *baseUrl = [[HMAccount currentAccount] getBaseUrl];
    NSString *filterString = [self filterString];
    
    NSString *url = [[[[[[baseUrl
        stringByAppendingString:@"/apps/"]
        stringByAppendingString:self.className]
        stringByAppendingString:@"?filter="]
        stringByAppendingString:filterString]
        stringByAppendingString:@"&token="]
        stringByAppendingString:token];
    
    NSLog(@"url %@", url);
    
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
