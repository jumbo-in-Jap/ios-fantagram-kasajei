//
//  MoreAppViewController.m
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/14.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import "MoreAppViewController.h"
#import "MoreAppCell.h"
#import "VKSocialKit.h"
#import "UserDefaults.h"
#import "UIKitHelper.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>


@interface MoreAppViewController ()
@property(nonatomic, strong) NSMutableArray *moreAppArray;
@end

@implementation MoreAppViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (![VKSocialKit hasSocialFramework]) {
        self.socialSegment.hidden = true;
    }
    
    self.moreAppArray = [[NSMutableArray alloc] init];
    __weak MoreAppViewController *blockSelf = self;
    NSString *urlString = NSLocalizedString(@"https://s3-ap-northeast-1.amazonaws.com/monocolorcam/MoreApp.json", nil);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"App.net Global Stream: %@", JSON);
        blockSelf.moreAppArray = JSON;
        [blockSelf.tableView reloadData];
    } failure:nil];
    [operation start];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    int segment = 0;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULTS_SOCIA_TYPE]) {
        case kVKTwitter:
            segment = 0;
            break;
        case kVKFacebook:
            segment = 1;
            break;
        default:
            break;
    }
    [self.socialSegment setSelectedSegmentIndex:segment];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.moreAppArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.moreAppArray objectAtIndex:section] objectForKey:@"SectionName"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    LOG(@"%d", [[[self.moreAppArray objectAtIndex:section] objectForKey:@"Apps"] count]);
    return [[[self.moreAppArray objectAtIndex:section] objectForKey:@"Apps"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MoreAppCell";
    MoreAppCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    NSDictionary *appDic = [[[self.moreAppArray objectAtIndex:indexPath.section] objectForKey:@"Apps"] objectAtIndex:indexPath.row];
    
    NSURL *appIconURL = [NSURL URLWithString:[appDic objectForKey:@"iconURL"]];
    UIImage *placeholderImage = [UIImage imageNamed:@"sample.jpg"];
    [cell.iconImageView setImageWithURL:appIconURL placeholderImage:placeholderImage];
    
    [cell.appNameLabel setText:[appDic objectForKey:@"AppName"]];
    [cell.descriptionLabel setText:[appDic objectForKey:@"Description"]];
    
    // FIXME: MoreAppCell.mでやりたい
    cell.iconImageView.layer.cornerRadius = 10;
    cell.iconImageView.clipsToBounds = true;
    
    // Configure the cell...
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *appDic = [[[self.moreAppArray objectAtIndex:indexPath.section] objectForKey:@"Apps"] objectAtIndex:indexPath.row];
    // もし、iOS6以上なら
    int appId = [appDic integerForKey:@"AppId"];
    if (NSClassFromString(@"SKStoreProductViewController") != nil && appId != -1) {
        NSDictionary *params = @{ SKStoreProductParameterITunesItemIdentifier : @(appId) };
        SKStoreProductViewController *store = [[SKStoreProductViewController alloc] init];
        store.delegate = self;
        [store loadProductWithParameters:params completionBlock:^(BOOL result, NSError *error) {
            if (!result) {
                double delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self dismissViewControllerAnimated:YES
                                             completion:nil];
                    
                });
            }
        }];
        [self presentViewController:store animated:YES completion:nil];
    }else{
        NSString *appURLString = [appDic objectForKey:@"AppURL"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURLString]];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setSelected:false];
    }
    
    
}

- (void)viewDidUnload {
    [self setBannerView:nil];
    [self setBannerView:nil];
    [self setSocialSegment:nil];
    [super viewDidUnload];
}

//iAd取得成功
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"iAd取得成功");
}

//iAd取得失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"iAd取得失敗");
}

// StoreKitのdelegate
-(void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 nil;
                             }];
}

// SegmentedControllerの値が変わったら
- (IBAction)changeValueSocialSegment:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    
    VKSocialType socialType;
    switch (segment.selectedSegmentIndex) {
        case 0:
            socialType = kVKTwitter;
            break;
        case 1:
            socialType = kVKFacebook;
            break;
        default:
            break;
    }
    [NSUserDefaults synchronize:^(NSUserDefaults *ud){
        [ud setInteger:socialType forKey:USER_DEFAULTS_SOCIA_TYPE];
    }];
}
@end
