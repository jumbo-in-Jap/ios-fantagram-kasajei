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
#import "GAI.h"
#import "Parameter.h"
#import <Parse/Parse.h>

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

- (void)getMoreAppJson{
    // S3から、アプリjsonのローディングを行う
    [SVProgressHUD showWithStatus:@"loading..."];
    self.moreAppArray = [[NSMutableArray alloc] init];
    __weak MoreAppViewController *blockSelf = self;
    NSString *urlString = NSLocalizedString(@"JSON_URL", nil);
    LOG(@"`%@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        blockSelf.moreAppArray = JSON;
        [blockSelf.tableView reloadData];
        LOG(@"%@",JSON);
        [SVProgressHUD dismiss];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error , id JSON){
        [SVProgressHUD showErrorWithStatus:@"Failed..."];
    }];
    [operation start];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    // iOS6以下の時はソーシャルアカウントの切り替えはなし
    if (![VKSocialKit hasSocialFramework]) {
        self.socialSegment.hidden = true;
    }
    
    [self getMoreAppJson];
    
    
    // Admobを作る
    _admobBannerView = [[GADBannerView alloc]
                   initWithFrame:CGRectMake(0.0,
                                            0.0,
                                            GAD_SIZE_320x50.width,
                                            GAD_SIZE_320x50.height)];
    
    // 広告の「ユニット ID」を指定する。これは AdMob パブリッシャー ID です。
    _admobBannerView.adUnitID = MY_BANNER_UNIT_ID;
    
    // ユーザーに広告を表示した場所に後で復元する UIViewController をランタイムに知らせて
    // ビュー階層に追加する。
    _admobBannerView.rootViewController = self;
    [self.adMobView addSubview:_admobBannerView];
    
    // 一般的なリクエストを行って広告を読み込む。
    [_admobBannerView loadRequest:[GADRequest request]];
    
    // GAでトラッキング
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker trackView:@"MoreAppViewController"];
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
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController.parentViewController;
    LOG(@"%@",NSStringFromClass([vc class]));
    
    // badgeを0にする
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
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
    NSURLRequest *request = [NSURLRequest requestWithURL:appIconURL];
    
    [cell.appNameLabel setText:[appDic objectForKey:@"AppName"]];
    [cell.descriptionLabel setText:[appDic objectForKey:@"Description"]];
    
    // Pushの未読があるときだけ
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        cell.badgeImageView.alpha = [appDic boolForKey:@"newBadge"];
    }else{
        cell.badgeImageView.alpha = 0;
    }
    
    
    
    // FIXME: MoreAppCell.mでやりたい
//    cell.iconImageView.layer.cornerRadius = 5;
//    cell.iconImageView.clipsToBounds = true;

    
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
    
    NSString *appName = [appDic objectForKey:@"AppName"];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker trackEventWithCategory:@"MoreAppViewController" withAction:@"PressAppCell" withLabel:appName withValue:@1];
    
}

- (void)viewDidUnload {
    [self setBannerView:nil];
    [self setSocialSegment:nil];
    [self setAdMobView:nil];
    [super viewDidUnload];
}

#pragma mark 広告系のdelegate
//iAd取得成功
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    self.bannerView.hidden = false;
}

//iAd取得失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    self.bannerView.hidden = true;
}



#pragma mark StoreKitのdelegate
// StoreKitのdelegate
-(void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 nil;
                             }];
}


#pragma mark IBAction
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

#pragma mark PushAction
-(void)pushAction:(NSDictionary *)userInfo{
    LOG(@"");
    [self getMoreAppJson];
}

@end
