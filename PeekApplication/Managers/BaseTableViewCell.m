//
//  BaseTableViewCell.m
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import "BaseTableViewCell.h"

@implementation BaseTableViewCell


-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock;
{
    self.delegate = nil;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
