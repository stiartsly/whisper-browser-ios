//
//  AddDeviceViewController.m
//  Whisper
//
//  Created by suleyu on 17/6/9.
//  Copyright © 2017年 Kortide. All rights reserved.
//

#import "AddDeviceViewController.h"

@interface AddDeviceViewController ()
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
}
@property (assign,nonatomic) BOOL isFlashLightOn;
@property (strong,nonatomic) AVCaptureDevice *device;
@property (strong,nonatomic) AVCaptureDeviceInput *input;
@property (strong,nonatomic) AVCaptureMetadataOutput *output;
@property (strong,nonatomic) AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (strong,nonatomic) UIImageView *line;
@property (strong,nonatomic) UIButton *flashLightControlButton;
@end

@implementation AddDeviceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupCamera];
    [self setupIntroductionLable];
    [self setupFlashLightControlButton];
    [self setupScanLine];
    self.navigationItem.title = NSLocalizedString(@"添加设备", nil);
    self.view.backgroundColor = [UIColor blackColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_session startRunning];
    timer = [NSTimer scheduledTimerWithTimeInterval:.02
                                             target:self
                                             selector:@selector(scanLineAnimation)
                                             userInfo:nil
                                             repeats:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    num = 0;
    upOrdown = NO;
    self.isFlashLightOn = NO;
    [_session stopRunning];
    [timer invalidate];
    timer = nil;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupCamera
{
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"请在iPhone的“设置-隐私-相机”中允许使用相机" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];

    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_output setRectOfInterest: [self makeScanReaderInterestRect]];

    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
        
        if ([_output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        }
    }

    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = self.view.bounds;

    UIView* shadowView = [self makeScanCamareShadowView:[self makeScanReaderRect]];
    [self.view.layer insertSublayer:self.preview atIndex:0];
    [self.view addSubview:shadowView];
}

-(void)setupIntroductionLable
{
    CGRect rect = [self makeScanReaderRect];
    int centerX = self.view.bounds.size.width/2;
    int centerY = rect.origin.y+rect.size.height+30;

    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(0, 0, rect.size.width+60, 40)];
    labIntroudction.center = CGPointMake(centerX, centerY);
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.numberOfLines = 2;
    labIntroudction.font = [UIFont systemFontOfSize:15];
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.text=NSLocalizedString(@"将二维码置于矩形框内即可自动识别", nil);
    [self.view addSubview:labIntroudction];
}

-(void)setupFlashLightControlButton
{
    UIButton * flashLightControlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashLightControlButton = flashLightControlButton;
    flashLightControlButton.backgroundColor = [UIColor clearColor];
    flashLightControlButton.frame = CGRectMake(10, self.view.bounds.size.height-40, 60, 30);
    flashLightControlButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    flashLightControlButton.titleLabel.font = [UIFont systemFontOfSize:16];
    flashLightControlButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [flashLightControlButton setBackgroundImage:[UIImage imageNamed:@"flashlight"] forState:UIControlStateNormal];
    [flashLightControlButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flashLightControlButton setTitleColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [flashLightControlButton setTitle:NSLocalizedString(@"打开",nil) forState:UIControlStateNormal];
    [flashLightControlButton addTarget:self action:@selector(flashLightControl) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashLightControlButton];
}

-(void)setupScanLine
{
    CGRect rect = [self makeScanReaderRect];

    int imgSize = 20;
    int imgX = rect.origin.x;
    int imgY = rect.origin.y;
    int width = rect.size.width;
    int hight = rect.size.height+2;

    UIImageView * imageViewTL = [[UIImageView alloc]initWithFrame:CGRectMake(imgX,imgY,imgSize,imgSize)];
    imageViewTL.image = [UIImage imageNamed:@"scan_tl"];
    imgSize = imageViewTL.image.size.width;
    [self.view addSubview:imageViewTL];
    UIImageView * imageViewTR = [[UIImageView alloc]initWithFrame:CGRectMake(imgX+width-imgSize,imgY,imgSize,imgSize)];
    imageViewTR.image = [UIImage imageNamed:@"scan_tr"];
    [self.view addSubview:imageViewTR];
    UIImageView * imageViewBL = [[UIImageView alloc]initWithFrame:CGRectMake(imgX,imgY+hight-imgSize,imgSize,imgSize)];
    imageViewBL.image = [UIImage imageNamed:@"scan_bl"];
    [self.view addSubview:imageViewBL];
    UIImageView * imageViewBR = [[UIImageView alloc]initWithFrame:CGRectMake(imgX+width-imgSize,imgY+hight-imgSize,imgSize,imgSize)];
    imageViewBR.image = [UIImage imageNamed:@"scan_br"];
    [self.view addSubview:imageViewBR];

    /* up dwon line animation */
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 2)];
    _line.image = [UIImage imageNamed:@"scan_line"];
    [self.view addSubview:_line];
}

-(CGRect)makeScanReaderRect
{
    int screemWith = [UIScreen mainScreen].bounds.size.width;
    int screemHeight = [UIScreen mainScreen].bounds.size.height -64;
    
    float scanSize = (MIN(screemWith, screemHeight)*3.0f)/5.0f;
    CGRect scanRect = CGRectMake(0, 0, scanSize, scanSize);
    
    scanRect.origin.x += (screemWith/2)-(scanRect.size.width/2);
    scanRect.origin.y += (screemHeight/2)-(scanRect.size.height/2)-(screemHeight/12);
    
    return scanRect;
}

-(UIView*)makeScanCamareShadowView :(CGRect)InnerRect
{
    UIImageView* referenceImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    UIGraphicsBeginImageContext(referenceImage.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(ctx, 0,0,0, 0.5);
    CGSize screenSize =[UIScreen mainScreen].bounds.size;
    CGRect drawRect =CGRectMake(0, 0, screenSize.width,screenSize.height);

    CGContextFillRect(ctx, drawRect);
    
    drawRect = CGRectMake(InnerRect.origin.x-referenceImage.frame.origin.x, InnerRect.origin.y-referenceImage.frame.origin.y, InnerRect.size.width, InnerRect.size.height);
    CGContextClearRect(ctx, drawRect);

    UIImage* returnimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    referenceImage.image = returnimage;
    
    return referenceImage;
}

-(CGRect)makeScanReaderInterestRect
{
    int screenWidth = self.view.bounds.size.width;
    int screenHeight = self.view.bounds.size.height;
    CGRect rect = [self makeScanReaderRect];

    CGFloat x = rect.origin.y/screenHeight;
    CGFloat y = rect.origin.x/screenWidth;
    CGFloat regionWidth = rect.size.height/screenHeight;
    CGFloat regionHight = rect.size.width/screenWidth;

    return CGRectMake(x, y, regionWidth, regionHight);
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([metadataObjects count] >0)
    {
        if (self.isFlashLightOn)
        {
            [self flashLightControl];
        }
        
        [_session stopRunning];
        [timer invalidate];
        timer = nil;
        
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        [self scanComplete :metadataObject.stringValue];
    }
}

-(void)scanLineAnimation
{
    CGRect rect = [self makeScanReaderRect];
    int lineFrameX = rect.origin.x;
    int lineFrameY = rect.origin.y;
    int upDownHight = rect.size.height;
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(lineFrameX, lineFrameY+2*num, upDownHight, 2);
        if (2*num >= upDownHight-2) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(lineFrameX, lineFrameY+2*num, upDownHight, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
}

-(void)flashLightControl
{
    if([_device hasTorch] && [_device hasFlash])
    {
        [_device lockForConfiguration:nil];
        if(self.isFlashLightOn == NO)
        {
            [_device setTorchMode:AVCaptureTorchModeOn];
            [_device setFlashMode:AVCaptureFlashModeOn];
            [_flashLightControlButton setTitle:NSLocalizedString(@"关闭", nil) forState:UIControlStateNormal];
            self.isFlashLightOn = YES;
        }
        else
        {
            [_device setTorchMode:AVCaptureTorchModeOff];
            [_device setFlashMode:AVCaptureFlashModeOff];
            [_flashLightControlButton setTitle:NSLocalizedString(@"打开", nil) forState:UIControlStateNormal];
            self.isFlashLightOn = NO;
        }
        [_device unlockForConfiguration];
    }
}

-(void)scanComplete:(NSString*)deviceID
{
    NSError *error = nil;
    BOOL alreadyPaired = [[DeviceManager sharedManager] pairWithDevice:deviceID passWord:@"password" error:&error];

    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    else {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.removeFromSuperViewOnHide = YES;
        [self.view addSubview:hud];
        [hud show:YES];
    }

    if (error == nil)
    {
        if (alreadyPaired) {
            hud.labelText = NSLocalizedString(@"已添加过该设备", nil);
            hud.mode = MBProgressHUDModeText;
            [self performSelector:@selector(finish) withObject:nil afterDelay:1];
        }
        else {
            hud.labelText = NSLocalizedString(@"授权申请已发送", nil);
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_ok"]];
            hud.mode = MBProgressHUDModeCustomView;
            //[hud hide:YES afterDelay:1];
            [self performSelector:@selector(finish) withObject:nil afterDelay:1];
        }
    }
    else {
        NSString *errorText = NSLocalizedString(@"验证设备失败", nil);
//        if (error.code == ECSDevErrorCode_NoDevice) {
//            errorText = NSLocalizedString(@"设备不存在", nil);
//        }
        hud.labelText = errorText;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1];

        [_session startRunning];
        timer = [NSTimer scheduledTimerWithTimeInterval:.02
                                                 target:self
                                               selector:@selector(scanLineAnimation)
                                               userInfo:nil
                                                repeats:YES];
    }
}

-(void)finish
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
