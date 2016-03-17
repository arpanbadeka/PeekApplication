//
//  ViewController.m
//  PeekApplication
//
//  Created by Arpan Badeka on 3/13/16.
//  Copyright © 2016 abc. All rights reserved.
//

#import <SafariServices/SafariServices.h>
#import "ViewController.h"
#import "NetworkManager.h"
#import "BaseTableViewCell.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,OpenURLDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *result;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) NSMutableDictionary *resultHeights;
@property (assign, nonatomic) NSUInteger pageCount;
@property (assign, nonatomic) BOOL fetchedResults;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.pageCount = 0;
    
    self.resultHeights = [[NSMutableDictionary alloc] init];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 215.0f;
    self.tableView.hidden = YES;
    
    // Initialize Refresh Control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    // Configure Refresh Control
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    // Configure View Controller
    [self.tableView addSubview:refreshControl];
    
}

- (void)refresh:(id)sender
{
    [[NetworkManager sharedManager] getLatestTweets:^(NSDictionary *dict, NSError *err) {
        NSArray *result = [dict objectForKey:@"statuses"];
        [self.result addObjectsFromArray:result];
        NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
        self.pageCount++;
        for (int i = 0 ; i < result.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:(i) inSection:0]];
        }
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [(UIRefreshControl *)sender endRefreshing];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.spinner) {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner.center = self.view.center;
        [self.view addSubview:self.spinner];
    }
    
    [self.spinner startAnimating];
    [[NetworkManager sharedManager] getContentwithCompletionBlock:^(NSDictionary * dict, NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            self.result = [[NSMutableArray alloc] initWithArray: [dict objectForKey:@"statuses"] copyItems:YES];
            [self.spinner stopAnimating];
            [self.tableView reloadData];
            self.tableView.hidden = NO;
        });
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.result.count + 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.result.count) {
        return 44;
    }
    else if ([self.resultHeights objectForKey:[NSString stringWithFormat:@"%ld",(long)indexPath.row]]) {
    //    NSLog(@"calling me \n");
        return ((NSNumber*)[self.resultHeights objectForKey:[NSString stringWithFormat:@"%ld",(long)indexPath.row]]).floatValue;
    }
    else
    {
        CGFloat height;
        NSDictionary *tweet = self.result[indexPath.row];
        height += [self getTextSize:[tweet objectForKey:@"text"]];
        height += 60;
        
        NSString *mediaURL = [((NSDictionary*)((NSArray*)[[tweet objectForKey:@"entities"] objectForKey:@"media"])[0]) objectForKey:@"media_url"];
        if (mediaURL.length > 0) {
            NSDictionary *mediaArr = [[tweet objectForKey:@"entities"] objectForKey:@"media" ][0];
            CGFloat smallSize = ((NSString*)[[[mediaArr objectForKey:@"sizes"] objectForKey:@"small"] objectForKey:@"h"]).floatValue;
            height += smallSize;
        }
        
        [self.resultHeights setObject:[NSNumber numberWithFloat:height] forKey:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];

        return height;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == self.result.count) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadMore" forIndexPath:indexPath];
        return cell;
        
    }else {
        NSDictionary *tweet = self.result[indexPath.row];
        NSString *cellIdentifier = @"";
        NSString *mediaURL = [((NSDictionary*)((NSArray*)[[tweet objectForKey:@"entities"] objectForKey:@"media"])[0]) objectForKey:@"media_url"];
        if (mediaURL.length > 0) {
            cellIdentifier = @"imageCell";
        }else {
            cellIdentifier = @"textCell";
        }
        
        BaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        
        [cell setupCell:tweet withCompletionBlock:^{
            if(![self.resultHeights objectForKey:[NSString stringWithFormat:@"%ld",(long)indexPath.row]])
            {
                if([cellIdentifier isEqualToString:@"imageCell"])
                {
                    [tableView beginUpdates];
                    [tableView reloadRowsAtIndexPaths:@[indexPath]
                                     withRowAnimation:UITableViewRowAnimationFade];
                    [tableView endUpdates];
                }
            }
        }];
        
        if (!cell.delegate) {
            cell.delegate = self;
        }
        if(indexPath.row%2 ==0)
            cell.backgroundColor = [UIColor darkGrayColor];
        
        return cell;
    }
    return nil;
}

- (CGFloat)getTextSize:(NSString *)text
{
    CGSize sizeOfText = [text boundingRectWithSize: CGSizeMake(self.view.frame.size.width,CGFLOAT_MAX)
                                              options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                           attributes: [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:17.0f]
                                                                                   forKey:NSFontAttributeName]
                                              context: nil].size;
    
    return ceilf(sizeOfText.height);
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.userInteractionEnabled = NO;
    
    if(indexPath.row == self.result.count)
    {
        [[NetworkManager sharedManager] getNextPage:^(NSDictionary *dict, NSError *err) {
            NSArray *result = [dict objectForKey:@"statuses"];
            if (result.count > 0) {
                
                NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
                self.pageCount++;
                NSUInteger count = (result.count >= 19)?19:result.count;
                for (int i = 0 ; i < count; i++) {
                    [indexPaths addObject:[NSIndexPath indexPathForItem:(self.result.count+i) inSection:0]];
                }
                [self.result addObjectsFromArray:result];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                cell.userInteractionEnabled = YES;
            }
            else {
                cell.textLabel.text = @"No More Results";
                cell.textLabel.textColor = [UIColor lightGrayColor];

            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.result removeObjectAtIndex:indexPath.row];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [self.tableView reloadData];
    }
}


-(void)openURL:(NSURL*)url
{
    SFSafariViewController *webVC = [[SFSafariViewController alloc] initWithURL:url];
    [self.navigationController pushViewController:webVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
