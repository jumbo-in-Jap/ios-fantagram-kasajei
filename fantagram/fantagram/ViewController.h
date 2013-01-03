//
//  ViewController.h
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/02.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPUImageView;

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet GPUImageView *imageView;
- (IBAction)pressSaveBtn:(id)sender;
@end
