//
//  WZDemo0ViewController.m
//  WZMediaDemo
//
//  Created by Worthy on 16/8/17.
//  Copyright © 2016年 Worthy. All rights reserved.
//

#import "WZDemo0ViewController.h"

@interface WZDemo0ViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, assign) CGFloat lastPinchDistance;
@end

@implementation WZDemo0ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupCaptureSession];
    [self startSession];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.videoPreviewLayer.frame = self.previewView.bounds;
}

- (void)setupCaptureSession {
    // 1.创建会话
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    // 2.创建输入设备
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 3.创建输入
    NSError *error = nil;
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    // 3.创建输出
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    // 4.连接输入与会话
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    // 5.连接输出与会话
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    // 6.预览画面
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.videoPreviewLayer.frame = self.previewView.bounds;
    [self.previewView.layer addSublayer:self.videoPreviewLayer];
}

- (void)startSession {
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
}

- (void)stopSession {
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - Gesture

- (IBAction)pinchGestureRecognizer:(UIPinchGestureRecognizer *)sender {
    if (sender.numberOfTouches != 2) {
        return;
    }
    CGPoint point1 = [sender locationOfTouch:0 inView:self.overlayView];
    CGPoint point2 = [sender locationOfTouch:1 inView:self.overlayView];
    CGFloat distanceX = point2.x = point1.x;
    CGFloat distanceY = point2.y - point1.y;
    CGFloat distance = sqrtf(distanceX * distanceX +distanceY * distanceY);
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.lastPinchDistance = distance;
    }
    CGFloat change = distance - self.lastPinchDistance;
    change = change / CGRectGetWidth(self.view.bounds);
    [self zoomCamera:change];
    self.lastPinchDistance = distance;
}

#pragma mark - Action

- (IBAction)captureButtonClicked:(id)sender {
    // 1.获得连接
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    // 2.拍摄照片
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }];
}

- (IBAction)flashButtonClicked:(id)sender {
    if ([self.captureDevice isFlashActive]) {
        [self setFlashMode:AVCaptureFlashModeOff];
    }else{
        [self setFlashMode:AVCaptureFlashModeOn];
    }
}

- (IBAction)cameraPositionButtonClicked:(id)sender {
    AVCaptureDevice *device = nil;
    if (self.captureDevice.position == AVCaptureDevicePositionFront) {
        device = [self deviceWithPosition:AVCaptureDevicePositionBack];
    }else {
        device = [self deviceWithPosition:AVCaptureDevicePositionFront];
    }
    if (!device) {
        return;
    }else {
        self.captureDevice = device;
    }
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!error) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.captureDeviceInput];
        if ([self.captureSession canAddInput:input]) {
            [self.captureSession addInput:input];
            self.captureDeviceInput = input;
            [self.captureSession commitConfiguration];
        }
    }
}

#pragma mark - Setting

- (void)setFlashMode:(AVCaptureFlashMode)mode {
    if ([self.captureDevice isFlashModeSupported:mode]) {
        NSError *error = nil;
        if ([self.captureDevice lockForConfiguration:&error]) {
            [self.captureDevice setFlashMode:mode];
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (void)zoomCamera:(CGFloat)change {
    if (self.captureDevice.position == AVCaptureDevicePositionFront) {
        return;
    }
    if (![self.captureDevice respondsToSelector:@selector(videoZoomFactor)]){
        return;
    }
    NSError *error = nil;
    if ([self.captureDevice lockForConfiguration:&error]) {
        CGFloat max = MIN(self.captureDevice.activeFormat.videoMaxZoomFactor, 3.0);
        CGFloat factor = self.captureDevice.videoZoomFactor;
        CGFloat scale = MIN(MAX(factor + change, 1.0), max);
        self.captureDevice.videoZoomFactor = scale;
        [self.captureDevice unlockForConfiguration];
    }
}

@end
