//
//  ImageTableViewCell.m
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import "ImageTableViewCell.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@implementation ImageTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    self.iconImgView.image = nil;
}

-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock
{

    [super setupCell:dict withCompletionBlock:^{
        NSString *mediaURLString = [((NSDictionary*)((NSArray*)[[dict objectForKey:@"entities"] objectForKey:@"media"])[0]) objectForKey:@"media_url"];
        mediaURLString = [mediaURLString stringByAppendingString:@":small"];
        
        //[self.tweetImageView setImageWithURL: usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.tweetImageView setImageWithURL:[NSURL URLWithString:[mediaURLString stringByRemovingPercentEncoding]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.cellHeight = image.size.height + super.cellHeight;
                completionBlock();
            });
            
        } usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }];
    
}

@end
