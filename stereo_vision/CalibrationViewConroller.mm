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

- (UIImage*) findCorners;
- (NSData*) dataFromVector:(cv::vector<cv::Point2f>*) vector;
 
@end

@implementation CalibrationViewController

@synthesize imageView = _imageView;
@synthesize calibrationButton = _calibrationButton;
@synthesize captureBtn = _captureBtn;
@synthesize activityIndicator = _activityIndicator;
@synthesize waitPeriod = _waitPeriod;

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
        boardWidth = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"boardHeight"] intValue];
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
                //[self processFrame];
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

    delete _videoCapture;
    _videoCapture = nil;
    _captureBtn = nil;
}

/*
-(void)willMoveToParentViewController:(UIViewController *)parent
{
    [[_sessionManager mySession ] setDataReceiveHandler:self.navigationController.parentViewController withContext:nil];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [[_sessionManager mySession ] setDataReceiveHandler:self.navigationController.presentingViewController withContext:nil];
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
        _otherImageCount =0;
        return;
        
    }
    
    dispatch_queue_t myQueue = dispatch_queue_create("my calibration thread", NULL);
    [self.activityIndicator startAnimating];
    [self.captureBtn setEnabled:NO];
    [self.calibrationButton setEnabled:NO];
    dispatch_async(myQueue, ^{
        _objectPoints.resize(_imageCount);
        double rms =  calibrateCameras( _boardSize,_imagePoints, _objectPoints, _imageCount , _imageSize, _squareHeight, _squareWidth);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            NSString* message = [NSString stringWithFormat:@"Calibration Completed with rms %f" ,rms];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Calibration" message: message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            [self.captureBtn setEnabled:YES];
            [self.calibrationButton setEnabled:YES];
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
        [self.captureBtn setEnabled:NO];
        dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
        dispatch_async(myQueue, ^{
            UIImage* corners = [self findCorners];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.captureBtn setEnabled:YES];
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
        NSLog(@"own image count is %d",_imageCount);
    }
    UIImage * corners = ([UIImage imageWithCVMat:cornersImg]);
    
    return  corners;

}

// Called when the user taps the Capture button. Grab a frame and process it
- (IBAction)capturePressed:(UIButton *)sender
{
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
        [self capture];
    }
    else
    {
        [self fillVectorFromData:data :&(_imagePoints[1][_otherImageCount]) ];
        _otherImageCount ++ ; 
        NSLog(@"Other image count is %d",_otherImageCount);
    }
}

@end