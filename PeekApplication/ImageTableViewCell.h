//
//  ImageTableViewCell.h
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import "TextTableViewCell.h"

@interface ImageTableViewCell : TextTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *tweetImageView;

-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock;

@end
