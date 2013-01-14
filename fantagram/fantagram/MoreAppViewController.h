//
//  MoreAppViewController.h
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/14.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <StoreKit/StoreKit.h>
#import "GADBannerView.h"

@interface MoreAppViewController : UITableViewController<ADBannerViewDelegate, SKStoreProductViewControllerDelegate,GADBannerViewDelegate>{
    GADBannerView *_admobBannerView;
}
@property (weak, nonatomic) IBOutlet ADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIView *adMobView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *socialSegment;
- (IBAction)changeValueSocialSegment:(id)sender;

@end
