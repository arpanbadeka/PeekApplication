//
//  TextTableViewCell.h
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "BaseTableViewCell.h"


@interface TextTableViewCell : BaseTableViewCell<TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconImgView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *tweetLabel;

-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock;

@end
