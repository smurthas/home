//
//  HMAuthAlert.h
//  Home Base
//
//  Created by Simon Murtha Smith on 9/19/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMAuthAlert : NSObject <UIAlertViewDelegate>

@property (nonatomic, copy)void (^yesBlock)(void);
@property (nonatomic, copy)void (^noBlock)(void);

+ (void) yesNoWithTitle:(NSString*)title message:(NSString*)message yesBlock:(void (^)())yesBlock noBlock:(void (^)())noBlock;

@end