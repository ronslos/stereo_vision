//
//  ViewController.m
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "SessionManager.h"

@interface ViewController () <GKPeerPickerControllerDelegate>

@property (nonatomic) BOOL isConnected;

@end

@implementation ViewController

@synthesize isConnected = _isConnected;

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
    self.isConnected = NO;
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

/*
 Method      : viewWillAppear
 Parameters  : 
 Returns     :
 Description : This method gets called automatically when an existing view controller re-appears on screen.
               Used to retreive the session data handler from the view that was removed from screen.
 */
- (void)viewWillAppear:(BOOL)animated
{
    if (self.isConnected) {
        _sessionManager = [SessionManager instance];
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
}

/*
 Method      : connectPressed
 Parameters  :
 Returns     :
 Description : Action for the connect devices button.
 */
- (IBAction)connectPressed 
{
    // initialize a new session
    _sessionManager = [SessionManager instance];
    _sessionManager.viewDelegate = self;
    [_sessionManager initializeSession];
}

/*
 Method      : endedConnectionPhase
 Parameters  : 
 Returns     :
 Description : Notification from the SessionManager object that the creation of the session is completed
 */
- (void) endedConnectionPhase
{
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
        self.isConnected = YES;
        
}

/*
 Method      : calibratePressed
 Parameters  :
 Returns     :
 Description : Action for the calibration button.
 */
- (IBAction)calibratePressed {
    
    // move both iPhones to calibration , only if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToCalibration:self];
        [self performSegueWithIdentifier:@"moveToCalibrate" sender:self];
    }
    else {
        // alert that connection must be established first
        NSString *str = [NSString stringWithFormat:@"You need to connect the devices before starting calibration"]; 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait ..." message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
    
}

/*
 Method      : reconstructPressed
 Parameters  :
 Returns     :
 Description : Action for the reconstruction button.
 */
- (IBAction)reconstructPressed {
    
    // move both iPhones to reconstruction , only if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToReconstruction:self];
        [self performSegueWithIdentifier:@"moveToReconstruction" sender:self];
    }
    else {
        // alert that connection must be established first
        NSString *str = [NSString stringWithFormat:@"You need to connect the devices before starting reconstruction"]; 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait ..." message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
    
}

/*
 Method      : photoLibraryPressed
 Parameters  :
 Returns     :
 Description : Action for the Photo Library button.
 */
- (IBAction)photoLibraryPressed {
    // move to settings, and move other iPhone as well if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToLibrary:self];
    }
    [self performSegueWithIdentifier:@"moveToLibrary" sender:self];
}

/*
 Method      : settingsPressed
 Parameters  :
 Returns     :
 Description : Action for the settings button.
 */
- (IBAction)settingsPressed {
    // move to settings, and move other iPhone as well if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToSettings:self];
    }
    [self performSegueWithIdentifier:@"moveToSettings" sender:self];
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
    
    if(![whatDidIget caseInsensitiveCompare:@"move to calibration"])
    {
        // move to calibration view controller
        [self performSegueWithIdentifier:@"moveToCalibrate" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to reconstruction"])
    {
        // move to reconstruction view controller
        [self performSegueWithIdentifier:@"moveToReconstruction" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to settings"])
    {
        // move to settings view controller
        [self performSegueWithIdentifier:@"moveToSettings" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to library"])
    {
        // move to library view controller
        [self performSegueWithIdentifier:@"moveToLibrary" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"calculate time delay"])
    {
        // received time delay calculation (other device must be trailing this device) - send response
        [_sessionManager sendCalculateTimeDelayResponse:self];
    }
}

@end
