//
//  ReconstructionViewController.m
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReconstructionViewController.h"

@interface ReconstructionViewController ()

@end

@implementation ReconstructionViewController

@synthesize waitPeriod = _waitPeriod;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _sessionManager = [SessionManager instance];
    [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] != NULL) {
        self.waitPeriod = [(NSNumber*)[[NSUserDefaults standardUserDefaults] objectForKey:@"timeDelay"] doubleValue];
    }
    else {
        self.waitPeriod = 0;
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.  
        [_sessionManager sendMoveBackToMenu];
    }
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
