//
//  NetworkManager.m
//  VurbTest
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import "NetworkManager.h"
#import "Reachability.h"

#define kHostURL @"https://api.twitter.com/"
#define kAPIKey @"wuiJ8zVkv3Bu6rSQtEl6ka7BX"
#define kAPISecret @"mt1pO9LMILVyKAv3iK2NtNP5XP3yPTZBLNRFt49rdL8U4BWCo9"

static Reachability *reach = nil;

@interface NetworkManager()

@property (nonatomic) Reachability *internetReachability;

@property (strong,atomic) NSString *authToken;

@property (strong,nonatomic) NSString* nextStr;

@property (strong,nonatomic) NSString* refreshStr;

@end

@implementation NetworkManager

+ (id)sharedManager {
    static NetworkManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
        reach = [Reachability reachabilityWithHostName:kHostURL];
        [reach startNotifier];

    }
    return self;
}

- (void)getContentwithCompletionBlock:(void(^)(NSDictionary *,NSError *))completionHandler
{
    NSString *postURL = @"https://api.twitter.com/oauth2/token";
    
    NSString *base64Str = [[[NSString stringWithFormat:@"%@:%@",kAPIKey,kAPISecret] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];

    NSURL *url = [NSURL URLWithString:[postURL stringByRemovingPercentEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:[NSString stringWithFormat:@"Basic %@",base64Str] forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPMethod:@"POST"]; 

    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = request.allHTTPHeaderFields;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    if ([reach currentReachabilityStatus] != NotReachable) {
        
        NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:[@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (!data || error) {
                NSLog(@"Error : %@",error.localizedDescription);
            }
            
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            self.authToken = [jsonDict objectForKey:@"access_token"];
            
            NSString *searchString = @"https://api.twitter.com/1.1/search/tweets.json?q=%40Peek&count=20";
            NSURL *searchURL = [NSURL URLWithString:[searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            NSMutableURLRequest *searchRequest = [NSMutableURLRequest requestWithURL:searchURL
                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                               timeoutInterval:60.0];
            [searchRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.authToken] forHTTPHeaderField:@"Authorization"];
            
            NSURLSessionConfiguration *searchSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            searchSessionConfiguration.HTTPAdditionalHeaders = searchRequest.allHTTPHeaderFields;
            
            NSURLSession *searchSession = [NSURLSession sessionWithConfiguration:searchSessionConfiguration];

            NSURLSessionDataTask *searchTask = [searchSession dataTaskWithRequest:searchRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                if (!data || error) {
                    NSLog(@"Error : %@",error.localizedDescription);
                }
                
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                self.nextStr = [NSString stringWithFormat:@"%@",[[jsonDict objectForKey:@"search_metadata"]objectForKey:@"next_results"]];
                self.refreshStr = [NSString stringWithFormat:@"%@",[[jsonDict objectForKey:@"search_metadata"]objectForKey:@"refresh_url"]];
                completionHandler(jsonDict,nil);
            }];
            [searchTask resume];
            
        }];
        
        [task resume];
    } else {
        
        NSError *error = [[NSError alloc] initWithDomain:@"No Internet Connection" code:404 userInfo:nil];
        completionHandler(nil,error);
    }

}

- (void)getNextPage:(void(^)(NSDictionary *,NSError *))completionHandler
{
    NSString *searchString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json%@",self.nextStr];
    NSURL *searchURL = [NSURL URLWithString:searchString];
    
    NSMutableURLRequest *searchRequest = [NSMutableURLRequest requestWithURL:searchURL
                                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                             timeoutInterval:60.0];
    [searchRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.authToken] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *searchSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    searchSessionConfiguration.HTTPAdditionalHeaders = searchRequest.allHTTPHeaderFields;
    
    NSURLSession *searchSession = [NSURLSession sessionWithConfiguration:searchSessionConfiguration];
    
    NSURLSessionDataTask *searchTask = [searchSession dataTaskWithRequest:searchRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!data || error) {
            NSLog(@"Error : %@",error.localizedDescription);
        }
        
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        
        NSUInteger maxInt = INT64_MAX;
        for (NSDictionary *dict in [jsonDict objectForKey:@"statuses"]) {
            NSNumber *num = [dict objectForKey:@"id"];
            if(num.longValue < maxInt)
                maxInt = num.longValue;
        }
        
        self.nextStr = [[NSString stringWithFormat:@"?max_id=%ld&q=%%40peek&count=20",(maxInt-1)] stringByRemovingPercentEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(jsonDict,nil);
        });
        
    }];
    [searchTask resume];
    
}


- (void)getLatestTweets:(void(^)(NSDictionary *,NSError *))completionHandler
{
    NSString *searchString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json%@",self.refreshStr];
    NSURL *searchURL = [NSURL URLWithString:[searchString stringByRemovingPercentEncoding]];
    NSMutableURLRequest *searchRequest = [NSMutableURLRequest requestWithURL:searchURL
                                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                             timeoutInterval:60.0];
    [searchRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.authToken] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *searchSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    searchSessionConfiguration.HTTPAdditionalHeaders = searchRequest.allHTTPHeaderFields;
    
    NSURLSession *searchSession = [NSURLSession sessionWithConfiguration:searchSessionConfiguration];
    
    NSURLSessionDataTask *searchTask = [searchSession dataTaskWithRequest:searchRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!data || error) {
            NSLog(@"Error : %@",error.localizedDescription);
        }
        
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        self.refreshStr = [NSString stringWithFormat:@"%@",[[jsonDict objectForKey:@"search_metadata"]objectForKey:@"refresh_url"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(jsonDict,nil);
        });
        
    }];
    [searchTask resume];
}

@end
