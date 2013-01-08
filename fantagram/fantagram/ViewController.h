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
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIButton *flipCameraBtn;
- (IBAction)pressSaveBtn:(id)sender;
- (IBAction)changeSlider:(id)sender;
- (IBAction)pressFlipCameraBtn:(id)sender;
- (IBAction)pressFlashBtn:(id)sender;
@end
