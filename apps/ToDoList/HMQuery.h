//
//  HMQuery.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMQuery : NSObject

@property NSString *collectionName;
@property BOOL collections;
@property NSMutableDictionary *filters;

+ (HMQuery*) objectQueryWithCollectionName:(NSString*)collectionName;
+ (HMQuery*) collectionQuery;

- (void) getObjectInBackgroundWithId:(NSString*)_id;
- (void) whereKey:(NSString*)whereKey equalTo:(id)equalTo;
- (NSString*) filterString;

@end
