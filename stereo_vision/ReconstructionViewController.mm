//
//  ReconstructionViewController.m
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReconstructionViewController.h"

static int TEN_K = 51200/8;

@interface ReconstructionViewController ()

@property (nonatomic) double waitPeriod;
@property (nonatomic) double start;
@property (nonatomic) double interval;
@property (nonatomic) double rttTime;
@property (nonatomic, strong) NSMutableArray * rtts;

- (void) showCaptureOnScreen;
- (NSMutableData*) dataFromImage:(cv::Mat*) image;
- (void) imageFromData: (NSData *) data withSize:(cv::Size) size: (cv::Mat*) img; 
- (void) saveImage:(UIImage *)image withDepthMap: (cv::Mat*) depthMap withDisparity: (cv::Mat*) disparity;
- (void) displayLastImage;

@end

@implementation ReconstructionViewController

@synthesize waitPeriod = _waitPeriod;
@synthesize start = _start;
@synthesize interval = _interval;
@synthesize rttTime = _rttTime;
@synthesize rtts = _rtts;

@synthesize imageView = _imageView;
@synthesize captureBtn = _captureBtn;
@synthesize pictures = _pictures;
@synthesize pickAlg = _pickAlg;

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
    
	/* Additional setup after loading the view */
    
    // getting the handle for the session object 
    _sessionManager = [SessionManager instance];
    [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];

    // initializing the video capture functionality
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Video capture is not supported in the simulator");
#else
    _videoCapture = new cv::VideoCapture;
    if (!_videoCapture->open(CV_CAP_AVFOUNDATION))
    {
        NSLog(@"Failed to open video camera");
    }
    else {
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_EXPOSURE, AVCaptureExposureModeContinuousAutoExposure);
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_WHITEBALANCE, AVCaptureWhiteBalanceModeAutoWhiteBalance );
        _videoCapture->set(CV_CAP_PROP_IOS_DEVICE_FOCUS, AVCaptureFocusModeLocked );
    }
#endif
    _videoCapture -> grab();
    (*_videoCapture) >> _lastFrame;
    _imageSize = _lastFrame.size();
    _notCapturing = YES;
    _chunksReceived = YES;
    _pause = NO;
    _chunkCount = 0;
    _totalChunks = 0;
    _secondImg = cv::Mat(_imageSize,CV_8UC3);
    
    // creating the bitmap for undistorting and rectifying the captured images
    createMap(_imageSize, _Q ,_map11, _map12, _map21, _map22, _roi1, _roi2 );
    
    // loading the pre-calculated delay period of sending the capture indication to the other device
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] != NULL) {
        self.waitPeriod = [(NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] doubleValue];
    }
    else {
        self.waitPeriod = 0;
    }
    
    // loading the relative position of the device - left or right
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"side"] != NULL)
    {
        _isLeftCamera = [(NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"side"] hasPrefix:@"Left"] ? YES : NO;
    }
    NSLog(@"loading recon");
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"] != NULL) {
        NSArray * savedArray = (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"];
        self.pictures = [[NSMutableArray alloc] initWithArray:savedArray];
    }
    else {
        self.pictures = [[NSMutableArray alloc] init];
    }
    
    // starting new calculation of the wait period - if results are highky different from pre-calculated value, new value will be used
    _rttCount = 0;
    _rttGap = 0;
    self.rtts = [NSMutableArray arrayWithCapacity:5];
    
    [NSThread sleepForTimeInterval:0.5];
    self.start = CACurrentMediaTime();
    [_sessionManager sendUpdateDelay:self];
    
    [self showCaptureOnScreen];
    
}

/*
 Method      : showCaptureOnScreen
 Parameters  : 
 Returns     :
 Description : 
 */
-(void) showCaptureOnScreen
{
    sleep(2);
    dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
    
    dispatch_async(myQueue, ^{
        while(_notCapturing){
            if (_pause == YES)
            {
                sleep(2);
            }
            if (_videoCapture && _videoCapture->grab())
            {
                _pause = NO;
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
    // Release any retained subviews of the main view.
    [self setImageView:nil];
    [self setCaptureBtn:nil];
    [self setPickAlg:nil];
    [super viewDidUnload];
    delete _videoCapture;
    self.pictures = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
 Method      : viewWillDisappear
 Parameters  : 
 Returns     :
 Description : This method gets called automatically just as this view controller is taken of the screen.
               Used to perform tasks that must be done at the moment this view is being removed.
 */
- (void) viewWillDisappear:(BOOL)animated {
    // if back button was pressed, notify other device to move back as well
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [_sessionManager sendMoveBackToMenu];
    }
    [super viewWillDisappear:animated];
}

/*
 Method      : capture
 Parameters  :
 Returns     :
 Description : 
 */
- (void) capture
{
    if (_videoCapture && _videoCapture->grab())
    {
        _notCapturing = NO;
        (*_videoCapture) >> _lastFrame;
        cv::Mat grayFrame;
        cv::cvtColor(_lastFrame, grayFrame, CV_RGB2GRAY);
        
        // send captured image in packages
        NSData* data = [self dataFromImage:&grayFrame];
        NSUInteger chunkCount = (NSUInteger)(data.length / TEN_K) + (data.length % TEN_K== 0 ? 0:1) ;
        NSString *chunkCountStr = [NSString stringWithFormat:@"%d",chunkCount];
        NSData* chunkCountData = [chunkCountStr dataUsingEncoding: NSASCIIStringEncoding];
        [_sessionManager sendDataToPeers:NULL WithData:chunkCountData];
        NSData *dataToSend;
        NSRange range = NSMakeRange(0, 0);
        for(NSUInteger i=0;i<data.length;i+=TEN_K){
            range = NSMakeRange(i, TEN_K);
            dataToSend = [data subdataWithRange:range];
            [_sessionManager sendDataToPeers:NULL WithData:dataToSend];
        }
        NSUInteger remainder = (data.length % TEN_K);
        if (remainder != 0){
            range = NSMakeRange(data.length - remainder,remainder);
            dataToSend = [data subdataWithRange:range];
            [_sessionManager sendDataToPeers:NULL WithData:dataToSend];
        }
        
        // end of image sending code
        
        dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
        dispatch_async(myQueue, ^{
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                // [self.captureBtn setEnabled:YES];
                
            });
        });
        dispatch_release(myQueue);
    }
    else
    {
        NSLog(@"Failed to grab frame");
    }
}

/*
 Method      : dataFromDepthImage
 Parameters  : (cv::Mat*) depthImage - 
               (cv::Mat*) colorImage - 
 Returns     :
 Description : 
 */
- (NSData*) dataFromDepthImage:(cv::Mat*) depthImage andColorImage: (cv::Mat*) colorImage
{

    int matRows = colorImage->rows;
    int matCols = colorImage->cols;
    NSMutableData* data = [[NSMutableData alloc]init];
    cv::Vec3f pos;
    cv::Vec4b pix;
    float val;
    for (int i = 0; i < matRows; i++)
    {
        for (int j = 0; j < matCols; j++ )
        {
            pix = colorImage->at<cv::Vec4b>(i,j);
            pos = depthImage->at<cv::Vec3f>(i,j);
            [data appendBytes:(void*)(&pos[0]) length:sizeof(float)];
            [data appendBytes:(void*)(&pos[1]) length:sizeof(float)];
            [data appendBytes:(void*)(&pos[2]) length:sizeof(float)];
            val = (float)pix[0]/255;
            [data appendBytes:(void*)(&val) length:sizeof(float)];
            val = (float)pix[1]/255;
            [data appendBytes:(void*)(&val) length:sizeof(float)];
            val = (float) pix[2]/255;
            [data appendBytes:(void*)(&val) length:sizeof(float)];
//            [data appendBytes:(void*)(&one) length:sizeof(float)];
        }
    }
    return data;
}

/*
 Method      : dataFromImage
 Parameters  : (cv::Mat*) image - 
 Returns     :
 Description : 
 */
- (NSMutableData*) dataFromImage:(cv::Mat*) image
{
    int matRows = image->rows;
    int matCols = image->cols;
    NSMutableData* data = [[NSMutableData alloc]init];
    unsigned char *pix;
    for (int i = 0; i < matRows; i++)
    {
        for (int j = 0; j < matCols; j++ )
        {
            pix = &image->data[i * matCols + j ];
            [data appendBytes:(void*)pix length:1];
        }
    }
    return data;
}

/*
 Method      : imageFromData
 Parameters  : (NSData *) data - 
               (cv::Size) size - 
               (cv::Mat*) img - 
 Returns     :
 Description : 
 */
- (void) imageFromData: (NSData *) data withSize:(cv::Size) size: (cv::Mat*) img 
{
    unsigned char *pix=NULL , *bytes;
    bytes = (unsigned char*)[data bytes];
    for (int i = 0; i < size.height; i++)
    {
        for (int j = 0; j < size.width; j ++)
        {
            
            pix  = &bytes[i * size.width + j ];
            img->at<unsigned char>(i , 3*j+1 ) = *pix;
            img->at<unsigned char>(i , 3*j+2 ) = *pix;
            img->at<unsigned char>(i , 3*j ) = *pix;
            
            // NSLog(@"%d\n" ,i * size.width*3 + j);
        }
    }
}

/*
 Method      : saveImage
 Parameters  : (UIImage *)image - 
               (cv::Mat*) depthMap - 
               (cv::Mat*) disparity -
 Returns     :
 Description : 
 */
- (void) saveImage:(UIImage *)image withDepthMap: (cv::Mat*) depthMap withDisparity: (cv::Mat*) disparity
{
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSInteger imgNum = [[NSUserDefaults standardUserDefaults]integerForKey:@"imageNum" ];
    [UIImageJPEGRepresentation([UIImage imageWithCVMat:*disparity], 1.0) writeToFile:[documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"IMG_%d.%@", imgNum, @"jpg"]] options:NSAtomicWrite error:nil];
    NSString * picPath = [documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"IMG_%d.%@", imgNum, @"jpg"]];
    NSLog(@"url is %@" , picPath);
    
    // create and save deapth data
    cv::Mat imageMat = [image CVMat];
    NSData* data = [NSData dataWithData:[self dataFromDepthImage:depthMap andColorImage: &imageMat ]];
    NSString * depthPath = [documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"DEPTH_IMG_%d", imgNum]];
    [NSKeyedArchiver archiveRootObject:data toFile:depthPath];
    
    // create the date
    NSDate * date = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.YYYY"];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    // save description of picture in pictures array, and update the picture counter
    NSDictionary* pic = [[NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"IMG_%d", imgNum], @"name", dateString, @"date", picPath, @"url",depthPath , @"depth_url", nil];
    [self.pictures addObject:pic];
    NSArray * savedArray = [[NSArray alloc] initWithArray:self.pictures];
    [[NSUserDefaults standardUserDefaults] setObject:savedArray forKey:@"pictures"];
    imgNum++;
    [[NSUserDefaults standardUserDefaults] setInteger:imgNum forKey:@"imageNum"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

/*
 Method      : loadImage
 Parameters  :  
 Returns     :
 Description : 
 */
- (UIImage *) loadImage {
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSInteger imgNum = [[NSUserDefaults standardUserDefaults]integerForKey:@"imageNum" ];
    imgNum--;
    UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/IMG_%d.%@", documentsDirectoryPath, imgNum ,@"jpg"]];
    
    return result;
}

/*
 Method      : displayLastImage
 Parameters  :  
 Returns     :
 Description : 
 */
- (void) displayLastImage
{
    UIImage *image = [self loadImage];
    _imageView.image = image;
    _pause = YES;
    [self showCaptureOnScreen];
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
        // received capture indication
        [self.captureBtn setEnabled:NO];
        [self capture];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        // need to move back to the parent view controller
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"update delay"])
    {
        // received delay calculation message - need to send response
        [_sessionManager sendUpdateDelayResponse:self];
        
        // patch in case the other device missed the current's device first message
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
    else if (_chunksReceived == YES)
    {
        // handle the recieving of image data and rebuild image
        NSString* chunkCountStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        _totalChunks = [chunkCountStr intValue];
        _chunksReceived = NO;
        _imgData = [[NSMutableData alloc]init];
    }
    else
    {
        [_imgData appendData:data];
        _chunkCount++;
        NSLog(@"%d" , _chunkCount);
        if(_chunkCount == _totalChunks)
        {
            _chunksReceived = YES ;
            _chunkCount = 0;
            [self imageFromData:_imgData withSize:_imageSize :&_secondImg];
            cv::Mat gray1,gray2;
            cv::cvtColor(_lastFrame, gray1, CV_RGB2GRAY);
            cv::cvtColor(_secondImg, gray2, CV_RGB2GRAY);
            _notCapturing = YES;
            if (_isLeftCamera){
                reconstruct(_imageSize, &gray1, &gray2, &_depthImg, _map11, _map12, _map21, _map22, _roi1, _roi2 ,_Q, self.pickAlg.selectedSegmentIndex);
                self.imageView.image = [UIImage imageWithCVMat:gray2];
                cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
                [self saveImage:[UIImage imageWithCVMat:_lastFrame] withDepthMap:&_depthImg withDisparity:&gray2];
            }
            else
            {
                reconstruct(_imageSize, &gray2, &gray1, &_depthImg, _map21, _map22, _map11, _map12, _roi2, _roi1 ,_Q, self.pickAlg.selectedSegmentIndex);
                self.imageView.image = [UIImage imageWithCVMat:gray1];
                cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
                [self saveImage:[UIImage imageWithCVMat:_lastFrame] withDepthMap:&_depthImg withDisparity:&gray1];
            }
            
            [self.captureBtn setEnabled:YES];
            [self displayLastImage];
        }
    }
}

/*
 Method      : capturePressed
 Parameters  : (UIButton *)sender
 Returns     :
 Description : Action for the capture button
 */
- (IBAction)capturePressed:(UIButton *)sender
{
    [self.captureBtn setEnabled:NO];
    [_sessionManager sendClick: self];
    [NSThread sleepForTimeInterval:self.waitPeriod];
    [self capture];
}


@end
