//
//  HMQuery.h
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/17/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMQuery : NSObject

+ (HMQuery*) queryWithClassName:(NSString*)className;

- (void) getObjectInBackgroundWithId:(NSString*)_id;
- (void) whereKey:(NSString*)whereKey equalTo:(id)equalTo;
- (void) findObjectsInBackgroundWithBlock:(void (^)(NSArray *object, NSError* error))callbackBlock;

@end
