//
//  CalibrationViewController.h
//  3d_visioin
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#include "File.h"
#import "SessionManager.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <UIKit/UIKit.h>

@interface CalibrationViewController : UIViewController <GKPeerPickerControllerDelegate>

{
    cv::VideoCapture *_videoCapture;
    cv::Mat _lastFrame;
    cv::vector<cv::vector<cv::Point2f> > _imagePoints[2];
    cv::vector<cv::vector<cv::Point3f> > _objectPoints;
    cv::Size _boardSize;
    cv::Size _imageSize;
    float _squareHeight;
    float _squareWidth;
    int _imageCount;
    int _otherImageCount;
    bool _notCapturing;
    SessionManager* _sessionManager;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *calibrationButton;
@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic) double waitPeriod;

- (IBAction)Calibrate:(UIButton *)sender;
- (IBAction)capturePressed:(UIButton *)sender;

- (void) capture;
- (void) showCaptureOnScreen;

@end