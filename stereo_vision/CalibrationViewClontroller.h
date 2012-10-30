//
//  CalibrationViewController.h
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#ifndef calibrationviewcontroller_h_
#define calibrationviewcontroller_h_

#include "OpenCVCalculations.h"
#import "SessionManager.h"
#import "TimeDelayCalculation.h"
#import <QuartzCore/CAAnimation.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <UIKit/UIKit.h>

@interface CalibrationViewController : UIViewController <GKPeerPickerControllerDelegate>
{
    cv::VideoCapture *_videoCapture;
    // stores last captured frame
    cv::Mat _lastFrame;
    // data structure which stores all the captured chessboard corners from both devices
    cv::vector<cv::vector<cv::Point2f> > _imagePoints[2];
    // data structure which stores the synthesized object points for calibration process
    cv::vector<cv::vector<cv::Point3f> > _objectPoints;
    cv::Size _boardSize;
    cv::Size _imageSize;
    float _squareHeight;
    float _squareWidth;
    // number of images captured in calibration process in current device
    int _imageCount;
    // number of images captured in calibration process in paired device
    int _otherImageCount;
    // flag used to exit capture loop
    bool _notCapturing;
    // flag used when capture process finished on current device
    bool _finishedCapture;
    // flag used when capture process finished on paired device
    bool _otherFinishedCapture;
    // flag used while calibration function is processing
    bool _calibrating;
    // Session Manager object pointer
    SessionManager* _sessionManager;
    
    // number of messages sent between devices for delay calculation
    int _rttCount;
    // round trip delay time (used for synchronization)
    int _rttGap;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *calibrationButton;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)Calibrate:(UIButton *)sender;
- (IBAction)capturePressed:(UIButton *)sender;

- (void) capture;
- (void) showCaptureOnScreen;

@end

#endif
