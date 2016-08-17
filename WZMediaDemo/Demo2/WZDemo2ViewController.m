//
//  WZDemo2ViewController.m
//  WZMediaDemo
//
//  Created by Worthy on 16/8/17.
//  Copyright © 2016年 Worthy. All rights reserved.
//

#import "WZDemo2ViewController.h"

@interface WZDemo2ViewController ()
@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetReaderTrackOutput *videoOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *audioOutput;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, assign) BOOL videoAppendFinish;
@property (nonatomic, assign) BOOL audioAppendFinish;

@property (nonatomic, copy) NSString *outputPath;
@end

@implementation WZDemo2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:sourcePath] options:nil];
    
    self.outputPath = [self outputPath];
    self.reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    self.writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.outputPath] fileType:AVFileTypeMPEG4 error:nil];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    self.videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    self.audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:@{AVFormatIDKey:@(kAudioFormatLinearPCM)}];
    [self.reader addOutput:self.videoOutput];
    [self.reader addOutput:self.audioOutput];
    
    CGSize naturalSize = videoTrack.naturalSize;
    CGFloat ratio = 1.0;
    CGSize outputSize = CGSizeMake(naturalSize.width * ratio, naturalSize.height * ratio);
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self videoOuputSettingWithSize:outputSize bitRate:1024*1024 profile:AVVideoProfileLevelH264MainAutoLevel]];
    self.videoInput.transform = videoTrack.preferredTransform;
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:[self audioOuputSetting]];
    [self.writer addInput:self.videoInput];
    [self.writer addInput:self.audioInput];
    
    
    self.videoQueue = dispatch_queue_create("com.worthy.videoReadingQueue", DISPATCH_QUEUE_SERIAL);
    self.audioQueue = dispatch_queue_create("com.worthy.audioReadingQueue", DISPATCH_QUEUE_SERIAL);
}
- (IBAction)outputButtonClicked:(id)sender {
    [[NSFileManager defaultManager] removeItemAtPath:self.outputPath error:nil];
    [self export];
}

- (void)export {
    if (self.reader.status != AVAssetReaderStatusUnknown) {
        return;
    }
    [self.reader startReading];
    [self.writer startWriting];
    [self.writer startSessionAtSourceTime:kCMTimeZero];
    [self.videoInput requestMediaDataWhenReadyOnQueue:self.videoQueue usingBlock:^{
        while (self.videoInput.readyForMoreMediaData) {
            CMSampleBufferRef sampleBuffer = [self.videoOutput copyNextSampleBuffer];
            BOOL success = NO;
            if (sampleBuffer) {
                @try {
                    success = [self.videoInput appendSampleBuffer:sampleBuffer];
                }@catch (NSException *exception) {
                    NSLog(@"%@",exception.reason);
                }@finally {
                    CFRelease(sampleBuffer);
                }
            }else {
                if (!_videoAppendFinish) {
                    _videoAppendFinish = YES;
                    [self.videoInput markAsFinished];
                    [self checkFinish];
                    break;
                }
            }
        }
    }];
    
    [self.audioInput requestMediaDataWhenReadyOnQueue:self.audioQueue usingBlock:^{
        while (self.audioInput.readyForMoreMediaData) {
            CMSampleBufferRef sampleBuffer = [self.audioOutput copyNextSampleBuffer];
            BOOL success = NO;
            if (sampleBuffer) {
                @try {
                    success = [self.audioInput appendSampleBuffer:sampleBuffer];
                }@catch (NSException *exception) {
                    NSLog(@"%@",exception.reason);
                }@finally {
                    CFRelease(sampleBuffer);
                }
            }else {
                if (!_audioAppendFinish) {
                    [self.audioInput markAsFinished];
                    _audioAppendFinish = YES;
                    [self checkFinish];
                    break;
                }
            }
        }
    }];
    
    
}

- (void)checkFinish {
    if (self.videoAppendFinish && self.audioAppendFinish) {
        [self.reader cancelReading];
        [self.writer finishWritingWithCompletionHandler:^{
            if (self.writer.error) {
                NSLog(@"write error:%@", self.writer.error.description);
            }else {
                NSLog(@"write success");
                UISaveVideoAtPathToSavedPhotosAlbum(self.outputPath, nil, nil, nil);
            }
        }];
    }
}

- (NSDictionary *)videoOuputSettingWithSize:(CGSize)size bitRate:(NSInteger)bitRate profile:(NSString *)profile{
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoHeightKey:@(size.height),
                                    AVVideoWidthKey:@(size.width),
                                    AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                    AVVideoCompressionPropertiesKey:@{
                                            AVVideoAverageBitRateKey:@(bitRate),
                                            AVVideoProfileLevelKey:profile,
                                            AVVideoCleanApertureKey:@{
                                                    AVVideoCleanApertureWidthKey:@(size.width),
                                                    AVVideoCleanApertureHeightKey:@(size.height),
                                                    AVVideoCleanApertureHorizontalOffsetKey:@(10),
                                                    AVVideoCleanApertureVerticalOffsetKey:@(10),
                                                    },
                                            AVVideoPixelAspectRatioKey:@{
                                                    AVVideoPixelAspectRatioHorizontalSpacingKey:@(1),
                                                    AVVideoPixelAspectRatioVerticalSpacingKey:@(1),
                                                    },
                                            },
                                    };
    return outputSettings;
}

- (NSDictionary *)audioOuputSetting {
    NSDictionary *outputSetting =  @{AVEncoderBitRateKey:@(128000),
                                     AVSampleRateKey:@(44100),
                                     AVNumberOfChannelsKey:@(2),
                                     AVFormatIDKey:@(kAudioFormatMPEG4AAC)};
    return outputSetting;
}

- (NSString *)outputPath {
    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [root stringByAppendingPathComponent:@"out.mp4"];
    return path;
}


@end
