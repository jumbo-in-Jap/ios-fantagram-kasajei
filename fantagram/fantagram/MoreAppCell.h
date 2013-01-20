//
//  MoreAppCell.h
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/14.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreAppCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property(weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property(weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *badgeImageView;
@end
