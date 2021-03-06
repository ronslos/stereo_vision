//
//  ReconstructionViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef reconstructionviewcontroller_h_
#define reconstructionviewcontroller_h_

#include "OpenCVCalculations.h"
#import "SessionManager.h"
#import "TimeDelayCalculation.h"
#import <QuartzCore/CAAnimation.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <UIKit/UIKit.h>

@interface ReconstructionViewController : UIViewController <GKPeerPickerControllerDelegate>
{
    cv::VideoCapture *_videoCapture;
    cv::Size _imageSize;
    cv::Mat _lastFrame;
    cv::Mat _secondImg;
    cv::Mat _depthImg;
    bool _notCapturing;
    bool _chunksReceived;
    bool _pause;
    bool _isLeftCamera;
    int _chunkCount;
    int _totalChunks;
    NSMutableData* _imgData;
    SessionManager* _sessionManager;
    cv::Mat _map11, _map12, _map21 ,_map22 ,_Q;
    cv::Rect _roi1 , _roi2;
    
    int _rttCount;
    int _rttGap;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (strong, nonatomic) NSMutableArray* pictures;
@property (weak, nonatomic) IBOutlet UISegmentedControl *pickAlg;

- (IBAction)capturePressed:(UIButton *)sender;
- (void) capture;

@end

#endif