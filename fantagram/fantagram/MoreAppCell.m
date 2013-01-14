//
//  MoreAppCell.m
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/14.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import "MoreAppCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation MoreAppCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        self.iconImageView.layer.cornerRadius = 5;
//        self.iconImageView.clipsToBounds = true;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
