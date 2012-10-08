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

- (void) showCaptureOnScreen;
- (NSMutableData*) dataFromImage:(cv::Mat*) image;
- (void) imageFromData: (NSData *) data withSize:(cv::Size) size: (cv::Mat*) img; 
- (void) saveImage:(UIImage *)image withDepthMap: (cv::Mat*) depthMap withDisparity: (cv::Mat*) disparity;
- (void) displayLastImage;

@end

@implementation ReconstructionViewController

@synthesize waitPeriod = _waitPeriod;
@synthesize imageView = _imageView;
@synthesize captureBtn = _captureBtn;
@synthesize pictures = _pictures;
@synthesize pickAlg = _pickAlg;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    
    _sessionManager = [SessionManager instance];
    [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];

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
    createMap(_imageSize, _Q ,_map11, _map12, _map21, _map22, _roi1, _roi2 );
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] != NULL) {
        self.waitPeriod = [(NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] doubleValue];
    }
    else {
        self.waitPeriod = 0;
    }
    NSLog(@"loading recon");
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"] != NULL) {
        NSArray * savedArray = (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"];
        self.pictures = [[NSMutableArray alloc] initWithArray:savedArray];
    }
    else {
        self.pictures = [[NSMutableArray alloc] init];
    }
    
    [self showCaptureOnScreen];
    
}

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

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setCaptureBtn:nil];
    [self setPickAlg:nil];
    [super viewDidUnload];
    delete _videoCapture;
    self.pictures = nil;
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.  
        [_sessionManager sendMoveBackToMenu];
    }
    [super viewWillDisappear:animated];
}

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
        
        [self.captureBtn setEnabled:NO];
        dispatch_queue_t myQueue = dispatch_queue_create("my op thread", NULL);
        dispatch_async(myQueue, ^{
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.captureBtn setEnabled:YES];
                
            });
        });
        dispatch_release(myQueue);
    }
    else
    {
        NSLog(@"Failed to grab frame");
    }
}
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
    
    // save description of picture in pictures array
    NSLog(@"saving image number %d" , imgNum); // debug
    NSDictionary* pic = [[NSDictionary alloc] initWithObjectsAndKeys: [NSString stringWithFormat:@"IMG_%d", imgNum], @"name", dateString, @"date", picPath, @"url",depthPath , @"depth_url", nil];

    NSLog(@"after dictionary"); // debug
    [self.pictures addObject:pic];
    NSLog(@"after adding a picture" ); // debug
    NSArray * savedArray = [[NSArray alloc] initWithArray:self.pictures];
    [[NSUserDefaults standardUserDefaults] setObject:savedArray forKey:@"pictures"];
    NSLog(@"after updating user defaults"); // debug
    imgNum++;
    [[NSUserDefaults standardUserDefaults] setInteger:imgNum forKey:@"imageNum"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (UIImage *) loadImage {
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSInteger imgNum = [[NSUserDefaults standardUserDefaults]integerForKey:@"imageNum" ];
    imgNum--;
    UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/IMG_%d.%@", documentsDirectoryPath, imgNum ,@"jpg"]];
    
    return result;
}

- (void) displayLastImage
{
    UIImage *image = [self loadImage];
    _imageView.image = image;
    _pause = YES;
    [self showCaptureOnScreen];
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
    else if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
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
            reconstruct(_imageSize, &gray1, &gray2, &_depthImg, _map11, _map12, _map21, _map22, _roi1, _roi2 ,_Q, self.pickAlg.selectedSegmentIndex);
            _notCapturing = YES;
            self.imageView.image = [UIImage imageWithCVMat:gray1];
            cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
            [self saveImage:[UIImage imageWithCVMat:_lastFrame] withDepthMap:&_depthImg withDisparity:&gray2];

            
//            
//            int i;
//            for(i=0; i< _depthImg.rows; i++)
//                for(int j=0; j<_depthImg.cols; j++)
//                    std::cout << _depthImg.at<cv::Vec3f>(i,j)[0] << "," << _depthImg.at<cv::Vec3f>(i,j)[1] << "," << _depthImg.at<cv::Vec3f>(i,j)[2] << ","<<std::endl;
//            std::cout <<" };" <<std::endl;
//            std::cout <<"char colors[] ={"<< std::endl;
//            cv::cvtColor(_lastFrame, _lastFrame, CV_BGR2RGB);
//            for(i=0; i< gray2.rows; i++)
//                for(int j=0; j<gray2.cols; j++)
//                    std::cout << (int)_lastFrame.at<cv::Vec3b>(i,j)[0] <<"," <<(int)_lastFrame.at<cv::Vec3b>(i,j)[1] <<"," <<(int)_lastFrame.at<cv::Vec3b>(i,j)[2] <<","<< std::endl;
            
            //************ Omer **********
            //UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NULL message:@"Would you like to save?" delegate:self cancelButtonTitle:@"Discard" otherButtonTitles:@"save", nil];
            //[alert show];
            //[alert release];
            [self displayLastImage];
        }
    }
}

- (IBAction)capturePressed:(UIButton *)sender
{
    [_sessionManager sendClick: self];
    [NSThread sleepForTimeInterval:self.waitPeriod];
    [self capture];
}

//
//#pragma mark -
//#pragma mark UIAlertViewDelegate
//
//- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex==1)
//        [self saveImage:[UIImage imageWithCVMat:_depthImg]];
//}
//

@end
