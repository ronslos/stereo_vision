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


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.isConnected = NO;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

/*
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
     
}
 */

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}


- (void)viewWillAppear:(BOOL)animated
{
    if (self.isConnected) {
        _sessionManager = [SessionManager instance];
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
}


- (IBAction)connectPressed 
{
    _sessionManager = [SessionManager instance];
    _sessionManager.viewDelegate = self;
    [_sessionManager initializeSession];
}

- (void) endedConnectionPhase
{
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
        self.isConnected = YES;
        
}

- (IBAction)calibratePressed {
    
    // move both iPhones to calibration , only if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToCalibration:self];
        [self performSegueWithIdentifier:@"moveToCalibrate" sender:self];
    }
    else {
        NSString *str = [NSString stringWithFormat:@"You need to connect the devices before starting calibration"]; 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait ..." message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
    
}

- (IBAction)reconstructPressed {
    
    // move both iPhones to reconstruction , only if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToReconstruction:self];
        [self performSegueWithIdentifier:@"moveToReconstruction" sender:self];
    }
    else {
        NSString *str = [NSString stringWithFormat:@"You need to connect the devices before starting reconstruction"]; 
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait ..." message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
    
}

- (IBAction)photoLibraryPressed {
    // move to settings, and move other iPhone as well if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToLibrary:self];
    }
    [self performSegueWithIdentifier:@"moveToLibrary" sender:self];
}

- (IBAction)settingsPressed {
    // move to settings, and move other iPhone as well if connected
    if (self.isConnected) {
        [_sessionManager sendMoveToSettings:self];
    }
    [self performSegueWithIdentifier:@"moveToSettings" sender:self];
}


#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if(![whatDidIget caseInsensitiveCompare:@"move to calibration"])
    {
        [self performSegueWithIdentifier:@"moveToCalibrate" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to reconstruction"])
    {
        [self performSegueWithIdentifier:@"moveToReconstruction" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to settings"])
    {
        [self performSegueWithIdentifier:@"moveToSettings" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to library"])
    {
        [self performSegueWithIdentifier:@"moveToLibrary" sender:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"calculate time delay"])
    {
        [_sessionManager sendCalculateTimeDelayResponse:self];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"calculate time delay response"])
    {
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
    }
    else {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unexpected message" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//[alert show];
    }
}


@end


