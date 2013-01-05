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
#import "GPUImageSelectiveColorFilter.h"

@interface ViewController ()
@property(nonatomic, strong) GPUImageStillCamera *stillCamera;
@property(nonatomic, strong) GPUImageFilterGroup *filterGroup;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    // 写真を3:4のサイズにするための比。今回は使わない
    double aspectRetio = 1.33333;
    
    // setting for stiilCamera
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    // 保存される画像はPortrait
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    // フィルターの設定
    //// まずフィルターグループを作る。フィルターを一つにまとめることで、あとで画像をつくるときに全部のフィルターがかかった画像が得られる
    self.filterGroup = [[GPUImageFilterGroup alloc] init];
    
    //// 最初のフィルター便宜的に
    GPUImageFilter *firstFilter = [[GPUImageFilter alloc] init];
    ////// 最初のフィルターには画像サイズを変えるための処理を入れる。これを入れないと画像サイズが大きすぎて、メモリーリークを起こして、アプリが落ちる
    [firstFilter forceProcessingAtSize:CGSizeMake(640, 640)];
    [self.filterGroup addFilter:firstFilter];
    
    
    // 変更を加えるところ-------------------------------------------

    GPUImageSelectiveColorFilter *selectiveColorFilter = [[GPUImageSelectiveColorFilter alloc] init];
    [self.filterGroup addTarget:selectiveColorFilter];
    
    //-------------------------------------------
    
    
    //// 最後のフィルター便宜的に
    GPUImageFilter *endFilter = [[GPUImageFilter alloc] init];
    [self.filterGroup addFilter:endFilter];
    
    
    // フィルターグループの設定
    //// フィルターグループでオリジナルの画像をinputとして持つフィルターを設定する
    [self.filterGroup setInitialFilters:@[firstFilter]];
    //// 一番最後のフィルターを設定する
    [self.filterGroup setTerminalFilter:endFilter];
    
    
    
    
    // フィルター構成
    [self.stillCamera addTarget:firstFilter];
    
    // 変更を加えるところ-------------------------------------------
    [firstFilter addTarget:selectiveColorFilter];

    [selectiveColorFilter addTarget:endFilter];
    //-------------------------------------------

    
    // フィルター構成終わり
    [endFilter addTarget:self.imageView];
    
    
    
    
    

    // stillCameraのキャプチャを開始する
    [self.stillCamera startCameraCapture];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark press btn
- (IBAction)pressSaveBtn:(id)sender {
    // 指定したFilterがかかった、画像が取得できる。そのために、プロパティでfilterをもたせている。今回はFilterGroupなのに注目
    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.filterGroup withCompletionHandler:^(UIImage *processedImage, NSError *error){
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
