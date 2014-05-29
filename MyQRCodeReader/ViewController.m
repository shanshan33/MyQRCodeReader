//
//  ViewController.m
//  MyQRCodeReader
//
//  Created by Shanshan ZHAO on 26/05/14.
//  Copyright (c) 2014 Shanshan ZHAO. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *previewUIView;
@property (weak, nonatomic) IBOutlet UILabel *readStatusLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *StartBarButton;

@property (strong, nonatomic) AVCaptureSession * captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * videoPreviewLayer;
@property (strong, nonatomic) AVAudioPlayer * audioPlayer;


@property (nonatomic) BOOL isReading;
@end

@implementation ViewController

#pragma mark - 
#pragma mark View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.isReading = NO;
    self.captureSession = nil;
    [self loadBeepSoundWhenFinishReadQRCode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 
#pragma mark Start Read QR Code

- (BOOL)startReading
{
    NSError *error;
    
    // add device camera
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    return YES;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput * captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    // create dispatch queue totally used by this task
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self
                                                queue:dispatchQueue];
    
    [captureMetadataOutput setMetadataObjectTypes:[NSArray  arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.previewUIView.layer.bounds];
    [self.previewUIView.layer addSublayer:self.videoPreviewLayer];
    
    [self.captureSession startRunning];
    
}


-(void)stopReading
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self.videoPreviewLayer removeFromSuperlayer];
}


- (void)loadBeepSoundWhenFinishReadQRCode
{
    NSString * beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL * beepURL = [NSURL URLWithString:beepFilePath];
    
    NSError * error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL
                                                              error:&error];
    if (error) {
        NSLog(@"Could not play beep mp3 file.");
        NSLog(@"%@",[error localizedDescription]);
    }
    else {
        [self.audioPlayer prepareToPlay];
    }

}


#pragma mark-
#pragma mark AVCaptureMetadataOutputObjects Delegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ((metadataObjects !=nil) && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject * metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type]isEqualToString:AVMetadataObjectTypeQRCode])
        {
            // since we preform on secondary thread so here need to perform on main thread
            
            [self.readStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(stopReading)
                                   withObject:nil
                                waitUntilDone:NO];
            [self.StartBarButton performSelectorOnMainThread:@selector(setText:)
                                                  withObject:@"Srart!!"
                                               waitUntilDone:NO];
            self.isReading = NO;
            
            if (self.audioPlayer) {
                [self.audioPlayer play];
            }
        }
    }
}


#pragma mark-
#pragma mark Actions

- (IBAction)startStopReadQRCode:(id)sender
{
    if (!self.isReading) {
        if ([self startReading]) {
            [self.StartBarButton setTitle:@"Stop"];
            [self.readStatusLabel setText:@"Scanning QR Code..."];
        }
    } else {
        
        [self stopReading];
        
        [self.StartBarButton setTitle:@"Start"];
        [self.readStatusLabel setText:@"QR Code is not Running yet ><"];
    }
    self.isReading = !self.isReading;
    
}


@end
