//
//  ViewController.h
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/02.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GPUImageView;

@interface ViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet GPUImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIButton *flipCameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *imagePickerBtn;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIButton *savePhotoBtn;
@property (weak, nonatomic) IBOutlet UISlider *hueSlider;
@property (weak, nonatomic) IBOutlet UISwitch *socialSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *socialIconView;
- (IBAction)pressCaptureBtn:(id)sender;
- (IBAction)pressSavePhotoBtn:(id)sender;
- (IBAction)changeSocialSwitch:(id)sender;
- (IBAction)changeSlider:(id)sender;
- (IBAction)pressFlipCameraBtn:(id)sender;
- (IBAction)pressFlashBtn:(id)sender;
- (IBAction)pressImagePickerBtn:(id)sender;
@end
