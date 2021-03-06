//
//  CalibrationViewController.mm
//
//  Created by Robin Summerhill on 02/09/2011.
//  Copyright 2011 Aptogo Limited. All rights reserved.
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

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

/*
 Method      : viewDidLoad
 Parameters  : 
 Returns     :
 Description : This method gets called automatically when this view controller is loaded to the screen.
               It is used to initialize all the objects required for the functionality of this view.
 */
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
    
    // getting the handle for the session object
    _sessionManager = [SessionManager instance];
    [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    
    // loading the pre-calculated delay period of sending the capture indication to the other device
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] != NULL) {
        self.waitPeriod = [(NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] doubleValue];
    }
    else {
        self.waitPeriod = 0;
    }
    
    // NSLog(@"wait period value when loaded: %f", self.waitPeriod); // debug
    
    // starting new calculation of the wait period - if results are highky different from pre-calculated value, new value will be used
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

/*
 Method      : showCaptureOnScreen
 Parameters  : 
 Returns     :
 Description : this function grabs frames from the videCapture and displays them on screen in a loop using an asynchronus thread 
 */
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

/*
 Method      : viewDidUnload
 Parameters  : 
 Returns     :
 Description : This method gets called automatically after this view controller is taken of the screen.
               It is not called immediately, rather at an undetermined time.
               It is used to release all the objects that were held by this viewcontroller.
 */
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

/*
 Method      : viewWillDisappear
 Parameters  : 
 Returns     :
 Description : This method gets called automatically just as this view controller is taken of the screen.
               Used to perform tasks that must be done at the moment this view is being removed.
 */
-(void) viewWillDisappear:(BOOL)animated 
{
    // if back button was pressed, notify other device to move back as well
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [_sessionManager sendMoveBackToMenu];
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
 Method      : Calibrate
 Parameters  : (UIButton *)sender
 Returns     :
 Description : Action for the calibrate button.
 */
- (IBAction)Calibrate:(UIButton *)sender
{
    
    if( _imageCount != _otherImageCount)
    {
        // if both devices have different image counts (if one device fails to discover corners for instance) the state is reinitialized and calibration process is started from beginning
        // none of the calibration methods are called in this case
        _imageCount = 0;
        _otherImageCount = 0;
        return;
        
    }
    
    _calibrating = YES;
    dispatch_queue_t myQueue = dispatch_queue_create("my calibration thread", NULL);
    // show activity indicator while calibrating
    [self.activityIndicator startAnimating];
    
    [self.captureBtn setEnabled:NO];
    [self.calibrationButton setEnabled:NO];
    // disable capture button on paired device
    [_sessionManager sendDisableCapture:self];
    // preform calibration in asynchronus thread so UI doesn't freeze
    dispatch_async(myQueue, ^{
        // resize the object points according to the number of images captured
        _objectPoints.resize(_imageCount);
        // preform calibration ( all parameters are stored in memory )
        double rms =  calibrateCameras( _boardSize,_imagePoints, _objectPoints, _imageCount , _imageSize, _squareHeight, _squareWidth);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            // show message on screen when calibration complete
            NSString* message = [NSString stringWithFormat:@"Calibration Completed with rms %f" ,rms];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Calibration" message: message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];

            // enable capture and calibration buttons on both devices when calibration completed
            [self.captureBtn setEnabled:YES];
            [self.calibrationButton setEnabled:YES];
            _calibrating = NO;
            [_sessionManager sendEnableCapture:self];
        });
        
    });
    dispatch_release(myQueue);
}

/*
 Method      : capture
 Parameters  :
 Returns     :
 Description : this method captures a single frame (called when capture button is pressed) and calls the findCorners method
               when corners our found they are displayed in the imageView
 */
-(void) capture
{
    if (_videoCapture && _videoCapture->grab())
    { 

        _notCapturing = NO;
        // grab frame
        (*_videoCapture) >> _lastFrame;
        cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
        // [self.captureBtn setEnabled:NO];
        dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
        dispatch_async(myQueue, ^{
            // find corners for captured frame
            UIImage* corners = [self findCorners];
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                // indicate that corners extraction calculation is finished
                // if other device finished as well, re-enable the buttons
                _finishedCapture = YES;
                if (_otherFinishedCapture == YES) {
                    [self.captureBtn setEnabled:YES];
                    [self.calibrationButton setEnabled:YES];
                }
                
                // set the imageView image property to the corners image for display
                self.imageView.image = corners;
            });
            _notCapturing = YES;
            // return to capture loop
            [self showCaptureOnScreen];
        });
        dispatch_release(myQueue);
    }
    else
    {
        NSLog(@"Failed to grab frame");        
    }
}

/*
 Method      : findCorners
 Parameters  : 
 Returns     : The image with the extracted corners pattern
 Description : Perform image processing on the last captured frame and display the results.
 */
- (UIImage *)findCorners
{
    cv::Mat grayFrame, cornersImg;
    // Convert captured frame to grayscale
    cv::cvtColor(_lastFrame, grayFrame, CV_RGB2GRAY);
    _imageSize = grayFrame.size();

    if(StereoCalib(grayFrame ,_boardSize,_imagePoints,_imageCount, cornersImg))
    {
        // create NSData object from chessboard points in preparation to send
        NSData* data = [self dataFromVector: &_imagePoints[0][_imageCount]];
        // send the chessboard points found to paired device
        [_sessionManager sendDataToPeers:NULL WithData:data];
        // increase image count
        _imageCount++;
    }
    // return uiimage to display corners
    UIImage * corners = ([UIImage imageWithCVMat:cornersImg]);
    
    return  corners;

}

/*
 Method      : capturePressed
 Parameters  : (UIButton *)sender
 Returns     :
 Description : Action for the capture button.
 */
- (IBAction)capturePressed:(UIButton *)sender
{
    // disable buttons and initialize capture process indicators to NO
    [self.captureBtn setEnabled:NO];
    [self.calibrationButton setEnabled:NO];
    _finishedCapture = NO;
    _otherFinishedCapture = NO;
    
    // send capture indication to the other device and wait the pre-calculated delay period
    [_sessionManager sendClick: self];
    [NSThread sleepForTimeInterval:self.waitPeriod];
    [self capture];
}

/*
 Method      : dataFromVector
 Parameters  : (cv::vector<cv::Point2f>*) vector - the vector of the corners locations
 Returns     :
 Description : this method creates NSData object from a cv::Vector<cv::Point2f> object in preparation to send data to paired device
 */
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

/*
 Method      : fillVectorFromData
 Parameters  : (NSData *) data - data to be reorgenized in vector
               (cv::vector<cv::Point2f>*) vector - points vector to be filled with data
 Returns     :
 Description : this function recovers the vector from the data after it is received from paired device
 */
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

/*
 Method      : receiveData
 Parameters  : (NSData *)data - the data received in the message
               (NSString *)peer  - the peer sending us this data
               (GKSession *)session - the session this peer belongs to
 Returns     :
 Description : This function gets called when a message is being received from the other device, and this view controller
               is set as the data receive handler.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if(![whatDidIget caseInsensitiveCompare:@"capture"])
    {
        if (_calibrating) {
            // do nothing since this device is in the middle of calibrating
        }
        else {
            // disable buttons and perform capture process
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
    else if (![whatDidIget caseInsensitiveCompare:@"enableCapture"])
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
        // need to move back to main menu
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"update delay"])
    {
        // received delay calculation message - need to send response
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
        // received calculation delay response - need to take a timestamp
        self.interval = CACurrentMediaTime();
        self.rttTime = self.interval - self.start;
        NSNumber * val = [NSNumber numberWithDouble:self.rttTime];
        [self.rtts insertObject:val atIndex:_rttCount];
        _rttCount++;
        if (_rttCount == 5) {
            // has 5 rtt values, performing calculation of delay time
            self.waitPeriod = [TimeDelayCalculation calculateUpdatedDelay:self.rtts withPrevDelay:self.waitPeriod];
            // this value is calculated locally, therfore not synchronized back to NSUserDefaults
        }
        else {
            // send another timestamp message
            self.start = CACurrentMediaTime();
            [_sessionManager sendUpdateDelay: self];
        }
        
    }
    
    // received data object
    else
    {
        // indicate other device finished extracting corners
        // If I also finished - re-enable the buttons
        _otherFinishedCapture = YES;
        if (_finishedCapture == YES) {
            [self.captureBtn setEnabled:YES];
            [self.calibrationButton setEnabled:YES];
        }
        [self fillVectorFromData:data :&(_imagePoints[1][_otherImageCount]) ];
        _otherImageCount ++ ; 
    }
}

@end
