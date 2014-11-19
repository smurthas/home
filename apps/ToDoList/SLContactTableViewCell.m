//
//  SLContactTableViewCell.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 10/25/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "SLContactTableViewCell.h"

@implementation SLContactTableViewCell

@synthesize accountID;
@synthesize baseUrl;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
