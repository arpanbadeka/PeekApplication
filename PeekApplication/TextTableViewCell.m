//
//  TextTableViewCell.m
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import "TextTableViewCell.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@implementation TextTableViewCell

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    self.iconImgView.image = nil;
}

-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock
{
    [super setupCell:dict withCompletionBlock:nil];
    
    self.userNameLabel.text = [(NSDictionary*)(((NSArray*)[[dict objectForKey:@"entities"] objectForKey:@"user_mentions"])[0]) objectForKey:@"name"];
    
    self.tweetLabel.delegate = self;
    self.tweetLabel.text = [dict objectForKey:@"text"];
    self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    
    NSString *iconStr = [[dict objectForKey:@"user"] objectForKey:@"profile_image_url"];
    NSURL *iconURL = [NSURL URLWithString:[iconStr stringByRemovingPercentEncoding]];
    
    [self.iconImgView setImageWithURL:iconURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            CGSize neededSize = [self.tweetLabel sizeThatFits:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
            self.cellHeight = neededSize.height + 50;

            completionBlock();
        });
    } usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
}


- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    if (self.delegate) {
        [self.delegate openURL:url];
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
