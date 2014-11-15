//
//  SLQuery.h
//  SlabClient
//
//  Created by Simon Murtha Smith on 11/14/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLQuery : NSObject

@property NSString *collectionName;
@property BOOL collections;
@property NSMutableDictionary *filters;

+ (SLQuery*) objectQueryWithCollectionName:(NSString*)collectionName;
+ (SLQuery*) collectionQuery;

- (void) getObjectInBackgroundWithId:(NSString*)_id;
- (void) whereKey:(NSString*)whereKey equalTo:(id)equalTo;
- (NSString*) filterString;


@end
