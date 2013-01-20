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
        self.iconImageView.clipsToBounds = true;
        self.iconImageView.layer.cornerRadius = 5;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.iconImageView.clipsToBounds = true;
    self.iconImageView.layer.cornerRadius = 5;
}
@end
