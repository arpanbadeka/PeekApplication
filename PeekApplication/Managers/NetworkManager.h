//
//  NetworkManager.h
//  VurbTest
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+ (id)sharedManager;

- (void)getContentwithCompletionBlock:(void(^)(NSDictionary *,NSError *))completionHandler;

- (void)getNextPage:(void(^)(NSDictionary *,NSError *))completionHandler;

- (void)getLatestTweets:(void(^)(NSDictionary *,NSError *))completionHandler;


@end
