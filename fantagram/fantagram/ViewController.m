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
#import "UIView+Genie.h"

@interface ViewController (){
    // あとで値を変えられるように
    GPUImageSelectiveColorFilter *_selectiveColorFilter;
    
    // captureBtnの場所を覚えておくため
    CGPoint captureBtnPosition;
}
@property(nonatomic, strong) GPUImageStillCamera *stillCamera; // カメラのinput
@property(nonatomic, strong) GPUImagePicture *stillImageSource; // imagepickerから選んだ時の画像
@property(nonatomic, strong) GPUImageFilterGroup *filterGroup; // フィルターグループ
@end

@implementation ViewController

// 初期設定や、Statusが変化した時に呼ばれ、Viewを変化させる
- (void)changeView{
    // フロントカメラがあるかどうか
    if (![self.stillCamera isFrontFacingCameraPresent]) {
        //        [self.flipCameraBtn setHidden:true];
    }
    
    // フラッシュのモード
    UIImage *flashBtnImg;
    switch (self.stillCamera.inputCamera.flashMode) {
        case AVCaptureFlashModeAuto:
            flashBtnImg = [UIImage imageNamed:@"flashAuto"];
            break;
        case AVCaptureFlashModeOn:
            flashBtnImg = [UIImage imageNamed:@"flashOn"];
            break;
        case AVCaptureFlashModeOff:
            flashBtnImg = [UIImage imageNamed:@"flashOff"];
            break;
        default:
            [self.flashBtn setHidden:true];
            break;
    }
    [self.flashBtn setImage:flashBtnImg forState:UIControlStateNormal];
    
    // FlashBtnはBackカメラの時のみ
    switch ([self.stillCamera cameraPosition]) {
        case AVCaptureDevicePositionBack:
            [self.flashBtn setHidden:false];
            break;
        case AVCaptureDevicePositionFront:
            [self.flashBtn setHidden:true];
        default:
            break;
    }
}

// すべてのボタンをEnableを変えるメソッド
- (void)setEnableAllBtn:(BOOL)enable{
    // すべてのsubviewを取ってくる
    for (UIButton *btn in [self.view subviews]) {
        // UIButtonクラスかどうか調べる
        if ([btn isKindOfClass:[UIButton class]]) {
            // enableを変える
            [btn setEnabled:enable];
        }
    }
}

// フィルターを作るメソッド。isCropはカメラのinputの時だけ。imagepickerから選んだときはallowEditiingで正方形になってるので使わない
- (void)createFilterGroupIsCrop:(BOOL)isCrop{
    double photoSize = 640;
    // フィルターの設定
    //// まずフィルターグループを作る。フィルターを一つにまとめることで、あとで画像をつくるときに全部のフィルターがかかった画像が得られる
    self.filterGroup = [[GPUImageFilterGroup alloc] init];
    
    //// 最初のフィルター便宜的に
    GPUImageFilter *firstFilter;
    if (isCrop){
        // 正方形にする
        firstFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0.125f, 1.0f, 0.75f)];
    }else{
        // 正方形にしない
        firstFilter = [[GPUImageFilter alloc] init];
    }
    

    [self.filterGroup addFilter:firstFilter];
    
    
    // 変更を加えるところ-------------------------------------------
    
    GPUImageGrayscaleFilter *grayScale = [[GPUImageGrayscaleFilter alloc] init];
    [self.filterGroup addTarget:grayScale];
    _selectiveColorFilter = [[GPUImageSelectiveColorFilter alloc] init];
    [self.filterGroup addTarget:_selectiveColorFilter];
    GPUImageLightenBlendFilter *lightenBlend = [[GPUImageLightenBlendFilter alloc] init];
    [self.filterGroup addTarget:lightenBlend];
    
    //-------------------------------------------
    
    
    //// 最後のフィルター便宜的に
    GPUImageFilter *endFilter = [[GPUImageFilter alloc] init];
    ////// 最後のフィルターには画像サイズを変えるための処理を入れる。これを入れないと画像サイズが大きすぎて、メモリーリークを起こして、アプリが落ちる
    [endFilter forceProcessingAtSize:CGSizeMake(photoSize, photoSize)];
    [self.filterGroup addFilter:endFilter];
    
    
    // フィルターグループの設定
    //// フィルターグループでオリジナルの画像をinputとして持つフィルターを設定する
    [self.filterGroup setInitialFilters:@[firstFilter]];
    //// 一番最後のフィルターを設定する
    [self.filterGroup setTerminalFilter:endFilter];
    
    // フィルター構成
    // 変更を加えるところ-------------------------------------------
    // ファーストフィルター → グレイスケール
    [firstFilter addTarget:grayScale];
    // ファーストフィルター → 赤色抽出フィルター
    [firstFilter addTarget:_selectiveColorFilter];
    
    // ファーストフィルター → 赤色抽出フィルター 　↓
    [_selectiveColorFilter addTarget:lightenBlend atTextureLocation:1]; // こっちが上
    // ファーストフィルター → グレイスケール      → ライトブレンド
    [grayScale addTarget:lightenBlend]; // こっちが下
    
    
    // ファーストフィルター → 赤色抽出フィルター　 ↓
    // ファーストフィルター → グレイスケール      → ライトブレンド → エンドフィルター
    [lightenBlend addTarget:endFilter];
    //-------------------------------------------
    
    
    // フィルター構成終わり
    [endFilter addTarget:self.imageView];
}


#pragma mark エフェクトの開始終了系
// カメラへのエフェクトを始める
- (void)startEffectToStillCamera{
    // まず、stillImageSourceをnilにしておく
    self.stillImageSource = nil;
    
    // ボタン系の設定
    [self.flashBtn setHidden:false];
    [self.flipCameraBtn setHidden:false];
    [self.savePhotoBtn setHidden:true];
    // 状況に合わせて、表示を変える
    [self changeView];
    
    // captureボタンのアニメーション
    __weak ViewController *blockSelf = self;
    [UIView animateWithDuration:0.7 animations:^(){
        [blockSelf.captureBtn setPosition:captureBtnPosition];
    }];
    
    // フィルター作成・正方形にする
    [self createFilterGroupIsCrop:true];
    // フィルターをつなげる
    [self.stillCamera removeAllTargets];
    [self.stillCamera addTarget:self.filterGroup];
    // stillCameraのキャプチャを開始する
    [self.stillCamera startCameraCapture];
    // スライダーの値を渡す
    [self changeSlider:self.hueSlider];
}

// カメラへのエフェクトを止める
- (void)stopEffectToStillCamera{
    [self.stillCamera removeAllTargets];
    [self.stillCamera stopCameraCapture];
}

// imagepickerから選んだ写真に対してフィルターを掛けるための設定
- (void)startEffectToStillImageSourceWithImage:(UIImage *)image{
    // GPUImagePictureを作る
    self.stillImageSource = [[GPUImagePicture alloc] initWithImage:image];
    // フィルターは正方形にしない
    [self createFilterGroupIsCrop:false];
    // stillImageSouceに作ったフィルターグループをつなげる
    [self.stillImageSource addTarget:self.filterGroup];
    // スライダーの値を渡す
    [self changeSlider:self.hueSlider];
    
    // カメラ系のボタンを消して、captureBtnをアニメーションして、savePhotoBtnを表示する
    __weak ViewController *blockSelf = self;
    [UIView animateWithDuration:0.7 animations:^(){
        [blockSelf.captureBtn setPosition:blockSelf.flashBtn.frame.origin];
        [blockSelf.flashBtn setHidden:true];
        [blockSelf.flipCameraBtn setHidden:true];
    }completion:^(BOOL success){
        [blockSelf.savePhotoBtn setHidden:false];
    }];
}

#pragma mark LifeCyle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // captureBtnのpositionを保存しておく
    captureBtnPosition = self.captureBtn.frame.origin;
    
    // setting for stiilCamera
    self.stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    // 保存される画像はPortrait
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    // カメラへのエフェクト開始
    [self startEffectToStillCamera];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setFlashBtn:nil];
    [self setFlipCameraBtn:nil];
    [self setImagePickerBtn:nil];
    [self setCaptureBtn:nil];
    [self setHueSlider:nil];
    [self setSavePhotoBtn:nil];
    [super viewDidUnload];
}



#pragma mark IBAction
// Saveボタンを押した時の挙動
- (IBAction)pressCaptureBtn:(id)sender {
    if (!self.stillImageSource) { // もし、ImagePickerから選んで編集している状況じゃなかったら、写真をとって
        // すべてのボタンを押せなくしておく
        [self setEnableAllBtn:false];
        // 指定したFilterがかかった、画像が取得できる。
        __weak id blockSelf = self;
        [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.filterGroup withCompletionHandler:^(UIImage *processedImage, NSError *error){
            // 保存のアニメーション
            [blockSelf saveAnimation:processedImage];
            // イメージを保存
            [blockSelf saveImage:processedImage];
        }];
        
    }else{// もしImagePickerから写真を選んで編集している状況だったら
        // BlocksKitを使ってる
        UIAlertView *alert = [UIAlertView alertViewWithTitle:@"写真を編集中です" message:@"編集画像を消去してカメラにもどってもよろしいですか？"];
        __weak id blockSelf = self;
        [alert addButtonWithTitle:@"NO"];
        [alert addButtonWithTitle:@"OK" handler:^(void) {
            // カメラへのエフェクトを再会する
            [blockSelf startEffectToStillCamera];
        }];
        [alert show];
    }
}

- (IBAction)pressSavePhotoBtn:(id)sender {
    // 画像を保存する
    UIImage *image = [self.filterGroup imageFromCurrentlyProcessedOutput];
    // 保存のアニメーション
    [self saveAnimation:image];
    // イメージを保存
    [self saveImage:image];
}

// Sliderを動かした時の挙動
- (IBAction)changeSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    // スライダーの値を設定する
    [_selectiveColorFilter setHueCenter:slider.value];
    
    // もしimagepickerから写真を選んで編集中の場合は、processImageする
    if (self.stillImageSource) {
        [self.stillImageSource processImage];
    }
}

// Cameraをフリップする
- (IBAction)pressFlipCameraBtn:(id)sender {
    [self.stillCamera rotateCamera];
    [self changeView];
}

- (IBAction)pressFlashBtn:(id)sender {
    // 次のFlashモードを決める
    AVCaptureFlashMode nextCaptureMode;
    switch (self.stillCamera.inputCamera.flashMode) {
        case AVCaptureFlashModeAuto:
            nextCaptureMode = AVCaptureFlashModeOn;
            break;
        case AVCaptureFlashModeOn:
            nextCaptureMode = AVCaptureFlashModeOff;
            break;
        case AVCaptureFlashModeOff:
            nextCaptureMode = AVCaptureFlashModeAuto;
            break;
        default:
            [self.flashBtn setHidden:true];
            return;
            break;
    }
    
    // Flashモードを設定する
    if ([self.stillCamera.inputCamera isFlashModeSupported:nextCaptureMode]) {
        NSError *error = nil;
        if ([self.stillCamera.inputCamera lockForConfiguration:&error]) {
            // モードの設定変更
            [self.stillCamera.inputCamera setFlashMode:nextCaptureMode];
            // Viewを変える
            [self changeView];
        }
    }
}

- (IBAction)pressImagePickerBtn:(id)sender {
    [self stopEffectToStillCamera];
    [self imagePickerController];
}



#pragma mark 写真保存後のアクション
// 写真を保存する前のアニメーション
- (void)saveAnimation:(UIImage *)image{
    
    // 保存するイメージをアニメーションのため、UIImageViewで表示する
    UIImageView *imageView = [UIImageView imageViewWithImage:image];
    [self.view addSubview:imageView];
    
    // BCGenieEffectのアニメーションを使っている
    __weak id blockSelf = self;
    CGRect endRect = self.imagePickerBtn.frame; // アニメーションの最終地点はimagepickerBtn
    [imageView genieInTransitionWithDuration:0.7
                             destinationRect:endRect
                             destinationEdge:BCRectEdgeTop
                                  completion:^{
                                      // imagePickerBtnに取った写真を載せる
                                      [_imagePickerBtn setImage:imageView.image forState:UIControlStateNormal];
                                      // imageViewを除く
                                      [imageView removeFromSuperview];
                                      // ボタンを使えるようにする
                                      [blockSelf setEnableAllBtn:true];
                                  }
     ];
}

// 写真を保存
- (void)saveImage:(UIImage *)image{
    // 非同期で保存する
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:image.CGImage
                                     metadata:nil
                              completionBlock:^(NSURL *assetURL, NSError *error){
                                  if (!error) {
                                      // 保存成功
                                      LOG(@"保存成功");
                                  }
                              }
         ];
    });
}


#pragma mark UIImagePickerController
// imagePickerを表示する
- (void)imagePickerController{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    // 正方形に切り取るようにしておく
    picker.allowsEditing = true;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:picker animated:YES];
}

// imagePickerで写真が選ばれたら呼び出されるdelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    __weak id blockSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^(){
        // allowEditingしているので、UIImagePickerControllerEditedImageで画像を取り出す
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        // 静止画へのフィルターの設定をする
        [blockSelf startEffectToStillImageSourceWithImage:image];
    }];
}

// imagePickerでcancelボタンを押された時
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if (!self.stillImageSource) { // もし静止画を持っていなかったら、カメラを再会する
        __weak id blockSelf = self;
        [picker dismissViewControllerAnimated:YES completion:^{
            [blockSelf startEffectToStillCamera];
        }];
    }else{ // 静止画を持っていたらそのまま静止画の編集画面に戻る
        [picker dismissModalViewControllerAnimated:YES];
    }
}
@end










