//
//  BaseTableViewCell.h
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OpenURLDelegate <NSObject>

@required
-(void)openURL:(NSURL*)url;
@end

@interface BaseTableViewCell : UITableViewCell

@property (nonatomic,assign) CGFloat cellHeight;
@property (weak, nonatomic) id<OpenURLDelegate> delegate;

-(void)setupCell:(NSDictionary*)dict withCompletionBlock:(void(^)(void))completionBlock;

@end
