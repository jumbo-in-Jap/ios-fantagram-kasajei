//
//  ViewController.m
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/02.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import "ViewController.h"
#import "UIKitHelper.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()
@property(nonatomic, strong) GPUImageStillCamera *stillCamera;
@property(nonatomic, strong) GPUImageFilter *filter;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    // setting for stiilCamera
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    // 保存される画像はPortrait
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    // フィルターの設定
    self.filter = [[GPUImageSepiaFilter alloc] init];
    [self.stillCamera addTarget:self.filter];
    [self.filter addTarget:self.imageView];
    [self.stillCamera startCameraCapture];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark press btn
- (IBAction)pressSaveBtn:(id)sender {
    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.filter withCompletionHandler:^(UIImage *processedImage, NSError *error){
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library writeImageToSavedPhotosAlbum:processedImage.CGImage
                                     metadata:nil
                              completionBlock:^(NSURL *assetURL, NSError *error){
                                  if (!error) {
                                      NSLog(@"保存成功！");
                                  }
                              }
         ];
    }];
}
@end
