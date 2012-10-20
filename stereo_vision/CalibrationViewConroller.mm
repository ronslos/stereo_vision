//
//  OpenCVClientViewController.m
//  OpenCVClient
//
//  Created by Robin Summerhill on 02/09/2011.
//  Copyright 2011 Aptogo Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

// UIImage extensions for converting between UIImage and cv::Mat

#define MAX_CALIBRATION_IMAGES 20

#import "CalibrationViewClontroller.h"

@interface CalibrationViewController() 

@property (nonatomic) double start;
@property (nonatomic) double interval;
@property (nonatomic) double rttTime;
@property (nonatomic, strong) NSMutableArray * rtts;
@property (nonatomic) double waitPeriod;

- (UIImage*) findCorners;
- (NSData*) dataFromVector:(cv::vector<cv::Point2f>*) vector;
 
@end

@implementation CalibrationViewController

@synthesize imageView = _imageView;
@synthesize calibrationButton = _calibrationButton;
@synthesize captureBtn = _captureBtn;
@synthesize activityIndicator = _activityIndicator;

@synthesize waitPeriod = _waitPeriod;
@synthesize rtts = _rtts;
@synthesize start = _start;
@synthesize interval = _interval;
@synthesize rttTime = _rttTime;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialise video capture - only supported on iOS device NOT simulator
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Video capture is not supported in the simulator");
#else
    _videoCapture = new cv::VideoCapture;
    if (!_videoCapture->open(CV_CAP_AVFOUNDATION))
    {
                             
        NSLog(@"Failed to open video camera");
    }
    else {
        // setting parameters of the camera
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_EXPOSURE, AVCaptureExposureModeContinuousAutoExposure);
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_WHITEBALANCE, AVCaptureWhiteBalanceModeAutoWhiteBalance );
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_FOCUS, AVCaptureFocusModeLocked );
    }
#endif
    _notCapturing = YES;
    
    // loading stored parameters of the board
    int boardWidth;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"boardWidth"] != NULL) {
        boardWidth = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"boardWidth"] intValue];
    }
    else {
        boardWidth = 9; // set to default number of internal corners along chessboard width
    }
    int boardHeight;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"boardHeight"] != NULL) {
        boardHeight = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"boardHeight"] intValue];
    }
    else {
        boardHeight = 6; // set to default number of internal corners along chessboard Height
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"squareHeight"] != NULL) {
        _squareHeight = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"squareHeight"] intValue];
    }
    else {
        _squareHeight = 1;
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"squareWidth"] != NULL) {
        _squareWidth = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"squareWidth"] intValue];
    }
    else {
        _squareWidth = 1;
    }
    
    _boardSize = cv::Size(boardWidth,boardHeight);
    _imageCount = 0;
    _otherImageCount = 0;
    _finishedCapture = YES;
    _otherFinishedCapture = YES;
    _calibrating = NO;
    _imagePoints[0].resize(MAX_CALIBRATION_IMAGES);
    _imagePoints[1].resize(MAX_CALIBRATION_IMAGES);
    _sessionManager = [SessionManager instance];
    [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] != NULL) {
        self.waitPeriod = [(NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] doubleValue];
    }
    else {
        self.waitPeriod = 0;
    }
    
    NSLog(@"wait period value when loaded: %f", self.waitPeriod); // debug
    
    _rttCount = 0;
    _rttGap = 0;
    self.rtts = [NSMutableArray arrayWithCapacity:5];
    
    [NSThread sleepForTimeInterval:0.5];
    self.start = CACurrentMediaTime();
    [_sessionManager sendUpdateDelay:self];
    
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidesWhenStopped:YES];
    [self showCaptureOnScreen];
    
}

-(void)showCaptureOnScreen
{
    sleep(2);
    dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
    
    dispatch_async(myQueue, ^{
        while(_notCapturing){
            if (_videoCapture && _videoCapture->grab())
            { 
                (*_videoCapture) >> _lastFrame;
                cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.imageView.image = [UIImage imageWithCVMat:_lastFrame]; 
                });
            }
            else
            {
                NSLog(@"Failed to grab frame");        
            }
        }
    });
    dispatch_release(myQueue);
}

- (void)viewDidUnload
{
    [self setActivityIndicator:nil];
    [self setCalibrationButton:nil];
    [self setImageView:nil];
    [self setCalibrationButton:nil];
    [self setCaptureBtn:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    self.imageView = nil;
    self.captureBtn = nil;
    _videoCapture->release();
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.  
        [_sessionManager sendMoveBackToMenu];
    }
    [super viewWillDisappear:animated];
}

/*
-(void) viewDidDisappear:(BOOL)animated {
    delete _videoCapture;
    _videoCapture->release();
    _videoCapture = nil;
    _imagePoints->clear();
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)Calibrate:(UIButton *)sender
{
    
    if( _imageCount != _otherImageCount)
    {
        _imageCount = 0;
        _otherImageCount = 0;
        return;
        
    }
    
    _calibrating = YES;
    dispatch_queue_t myQueue = dispatch_queue_create("my calibration thread", NULL);
    [self.activityIndicator startAnimating];
    // self.calibLabel.text = @"Calibrating...";
    [self.captureBtn setEnabled:NO];
    [self.calibrationButton setEnabled:NO];
    [_sessionManager sendDisableCapture:self];
    dispatch_async(myQueue, ^{
        _objectPoints.resize(_imageCount);
        double rms =  calibrateCameras( _boardSize,_imagePoints, _objectPoints, _imageCount , _imageSize, _squareHeight, _squareWidth);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            NSString* message = [NSString stringWithFormat:@"Calibration Completed with rms %f" ,rms];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Calibration" message: message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            // need to decide weather to check before re-enabling the capture button
            [self.captureBtn setEnabled:YES];
            [self.calibrationButton setEnabled:YES];
            _calibrating = NO;
            [_sessionManager sendEnableCapture:self];
        });
        
    });
    
    dispatch_release(myQueue);
}


-(void) capture
{
    if (_videoCapture && _videoCapture->grab())
    { 

        _notCapturing = NO;
        (*_videoCapture) >> _lastFrame;
        cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
        // [self.captureBtn setEnabled:NO];
        dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
        dispatch_async(myQueue, ^{
            UIImage* corners = [self findCorners];
            dispatch_sync(dispatch_get_main_queue(), ^{
                _finishedCapture = YES;
                if (_otherFinishedCapture == YES) {
                    [self.captureBtn setEnabled:YES];
                    [self.calibrationButton setEnabled:YES];
                }
                self.imageView.image = corners;
            });
            _notCapturing = YES;
            [self showCaptureOnScreen];
        });
        dispatch_release(myQueue);
    }
    else
    {
        NSLog(@"Failed to grab frame");        
    }
}

// Perform image processing on the last captured frame and display the results
- (UIImage *)findCorners
{
    cv::Mat grayFrame, cornersImg;
    // Convert captured frame to grayscale
    cv::cvtColor(_lastFrame, grayFrame, CV_RGB2GRAY);
    _imageSize = grayFrame.size();

    if(StereoCalib(grayFrame ,_boardSize,_imagePoints,_imageCount, cornersImg))
    {
        NSData* data = [self dataFromVector: &_imagePoints[0][_imageCount]];
        [_sessionManager sendDataToPeers:NULL WithData:data];
        _imageCount++;
        // NSLog(@"own image count is %d",_imageCount); // debug
    }
    UIImage * corners = ([UIImage imageWithCVMat:cornersImg]);
    
    return  corners;

}

// Called when the user taps the Capture button. Grab a frame and process it
- (IBAction)capturePressed:(UIButton *)sender
{
    [self.captureBtn setEnabled:NO];
    [self.calibrationButton setEnabled:NO];
    _finishedCapture = NO;
    _otherFinishedCapture = NO;
    [_sessionManager sendClick: self];
    [NSThread sleepForTimeInterval:self.waitPeriod];
    [self capture];
}

-(NSData*) dataFromVector:(cv::vector<cv::Point2f>*) vector
{
    NSUInteger size = vector->size();
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:2*size];
    cv::vector<cv::Point2f>::iterator iter;
    for (iter = vector->begin() ; iter<vector->end() ; iter++)
    {
        [array addObject: [NSNumber numberWithFloat:iter->x]];
        [array addObject: [NSNumber numberWithFloat:iter->y]];
    }
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:array];
    return data;
}

-(void) fillVectorFromData: (NSData *) data :(cv::vector<cv::Point2f>*) vector
{
    NSMutableArray* array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    vector->resize((int)[array count]/2);
    cv::vector<cv::Point2f>::iterator iter = vector->begin();
    NSEnumerator* enumerator = [array objectEnumerator];
    id object;
    while (object = [enumerator nextObject]) {
        iter->x = [object floatValue];
        object = [enumerator nextObject];
        iter->y = [object floatValue];
        iter++;
    }
}


#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if(![whatDidIget caseInsensitiveCompare:@"capture"])
    {
        if (_calibrating) {
            // do nothing since this device is in the middle of calibrating
        }
        else {
            [self.captureBtn setEnabled:NO];
            [self.calibrationButton setEnabled:NO];
            _finishedCapture = NO;
            _otherFinishedCapture = NO;
            [self capture];
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"disableCapture"])
    {
        if (_calibrating) {
            // I'm also calibrating so nothing is to be done
        }
        else {
            // I'm not calibrating - so don't allow anyone to capture with this device
            [self.captureBtn setEnabled:NO];
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"EnableCapture"])
    {
        if (_calibrating) {
            // I'm also calibrating so nothing is to be done
        }
        else {
            // I'm not calibrating - so allow capture to be pressed again
            [self.captureBtn setEnabled:YES];
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"update delay"])
    {
        [_sessionManager sendUpdateDelayResponse:self];
        
        // patch in case the other device missed your first message
        if (_rttCount == 0) {
            _rttGap++;
            if (_rttGap > 3){
                [_sessionManager sendUpdateDelay: self];
            }
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"update delay response"])
    {
        self.interval = CACurrentMediaTime();
        self.rttTime = self.interval - self.start;
        NSNumber * val = [NSNumber numberWithDouble:self.rttTime];
        [self.rtts insertObject:val atIndex:_rttCount];
        _rttCount++;
        if (_rttCount == 5) {
            // perform calculation of delay time
            self.waitPeriod = [TimeDelayCalculation calculateUpdatedDelay:self.rtts withPrevDelay:self.waitPeriod];
            // this value is calculated locally, therfore not synchronized back to NSUserDefaults
            NSLog(@"wait period value after re-calculating: %f", self.waitPeriod); // debug
        }
        else {
            // send another timestamp message
            self.start = CACurrentMediaTime();
            [_sessionManager sendUpdateDelay: self];
        }
        
    }
    // received data
    else
    {
        _otherFinishedCapture = YES;
        if (_finishedCapture == YES) {
            [self.captureBtn setEnabled:YES];
            [self.calibrationButton setEnabled:YES];
        }
        [self fillVectorFromData:data :&(_imagePoints[1][_otherImageCount]) ];
        _otherImageCount ++ ; 
        // NSLog(@"Other image count is %d",_otherImageCount); // debug
    }
}

@end
