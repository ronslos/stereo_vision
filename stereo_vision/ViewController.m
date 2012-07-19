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

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)connectPressed {
    _sessionManager = [SessionManager instance];
    [_sessionManager initializeSession];
}

- (IBAction)calibratePressed {
    // move other phone to calibration as well, and connect phones if needed
    if (![SessionManager isInitialized]) {
        // initialize session
        _sessionManager = [SessionManager instance];
        [_sessionManager initializeSession];
    }
    [_sessionManager sendMoveToCalibration:self];
    [self performSegueWithIdentifier:@"moveToCalibrate" sender:self];
}

- (IBAction)reconstructPressed {
    // move other phone to reconstruction as well, and connect phones if needed
    if (![SessionManager isInitialized]) {
        // initialize session
        _sessionManager = [SessionManager instance];
        [_sessionManager initializeSession];
    }
    [_sessionManager sendMoveToReconstruction:self];
    [self performSegueWithIdentifier:@"moveToReconstruction" sender:self];
    
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if(![whatDidIget caseInsensitiveCompare:@"move to calibration"])
    {
        [self calibratePressed];
    }
    else if (![whatDidIget caseInsensitiveCompare:@"move to reconstruction"])
    {
        [self reconstructPressed];
    }
}


@end


