//
//  SessionManager.m
//  3d_visioin
//
//  Created by Ron Slossberg on 4/30/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "SessionManager.h"

@interface SessionManager ()

@property (nonatomic) NSDate * start;
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic) NSTimeInterval totalTime;

@end

@implementation SessionManager

@synthesize mySession;
@synthesize start = _start;
@synthesize interval = _interval;
@synthesize totalTime = _totalTime;
@synthesize viewDelegate = _viewDelegate;

static SessionManager *gInstance = NULL;

+ (SessionManager *)instance
{
    @synchronized(self)
    {
        if (gInstance == NULL)
            gInstance = [[self alloc] init];
    }
    
    return(gInstance);
}

- (void) initializeSession
{
    peerPicker =  [[GKPeerPickerController alloc] init];
    peerPicker.delegate = self;

    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    peers=[[NSMutableArray alloc] init];
    [peerPicker show];
}

- (void) sendDataToPeers:(id) sender WithData:(NSData*) data 
{
	// Send the fart to Peers using teh current sessions
	[mySession sendData:data toPeers:peers withDataMode:GKSendDataReliable error:nil];
}

- (void) sendClick:(id) sender;
{
    NSString *str = @"capture";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendMoveToCalibration: (id) sender 
{
    NSString *str = @"move to calibration";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendMoveToReconstruction: (id) sender
{
    NSString *str = @"move to reconstruction";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendCalculateTimeDelay
{
    // prepare for sending timestamp message
    self.start = [NSDate date];
    
    NSString *str = @"calculate time delay";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendCalculateTimeDelayResponse
{
    NSString *str = @"calculate time delay response";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

// This creates a unique Connection Type for this particular applictaion
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type{
	// Create a session with a unique session ID - displayName:nil = Takes the iPhone Name
	GKSession* session = [[GKSession alloc] initWithSessionID:@"com.Calib.session" displayName:nil sessionMode:GKSessionModePeer];
    return session;
}

// Tells us that the peer was connected
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session{
	
	// Get the session and assign it locally
	session.delegate = self;
	//[session setDataReceiveHandler:self withContext:nil];
	self.mySession = session;
    
    //No need of the picekr anymore
	picker.delegate = nil;
    [picker dismiss];
}


// Function to receive data when sent from peer
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (![whatDidIget caseInsensitiveCompare:@"calculate time delay"])
    {
        [self sendCalculateTimeDelayResponse];
        if (_count == 0) {
            _gapCount++;
            if (_gapCount > 3){
                [self sendCalculateTimeDelay];
            }
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"calculate time delay response"])
    {
        self.interval = [self.start timeIntervalSinceNow];
        self.totalTime += self.interval;
        _count++;
        if (_count == 5) {
            if ([self.viewDelegate respondsToSelector:@selector(endedConnectionPhase)]){
                [self.viewDelegate endedConnectionPhase];
            }
            self.totalTime = self.totalTime / 5;
            NSNumber * delay = [NSNumber numberWithDouble:(self.totalTime / 2)];
            [[NSUserDefaults standardUserDefaults] setObject:delay forKey:@"timeDelay"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *str = [NSString stringWithFormat:@"Connected with time delay of %f", (self.totalTime/2)];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else {
            // send another timestamp message
            [self sendCalculateTimeDelay];
        }
        
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Received" message:whatDidIget delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

#pragma mark -
#pragma mark GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
    
	if (state == GKPeerStateConnected){
		// Add the peer to the Array
		[peers addObject:peerID];
		
        // alert end of connection phase
        //NSString *str = [NSString stringWithFormat:@"Connected with %@",[mySession displayNameForPeer:peerID]];
		//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//[alert show];
        
		// Used to acknowledge that we will be sending data
		[mySession setDataReceiveHandler:self withContext:nil];
        //[NSThread sleepForTimeInterval:2.5];
        
        // calculate the time delay between the devices
        _count = 0;
        _gapCount = 0;
		self.totalTime = 0;
        [self sendCalculateTimeDelay];
        
        /*
        for (int i=0; i < 10; i++){
            self.start = [NSDate date];
            [self sendCalculateTimeDelay];
            //sleep(0.5);
            [NSThread sleepForTimeInterval:2];
            //totalTime += self.interval;
        }
        */
        
        //while (_count < 5);
        /*
        self.totalTime = self.totalTime / 5;
        NSNumber * delay = [NSNumber numberWithDouble:(self.totalTime / 2)];
        [[NSUserDefaults standardUserDefaults] setObject:delay forKey:@"timeDelay"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        */
        
        /*
        [NSThread sleepForTimeInterval:2.5];
        // notify viewControllerDelegate that connection was established
        if ([self.viewDelegate respondsToSelector:@selector(endedConnectionPhase)]){
            [self.viewDelegate endedConnectionPhase];
        }
        */
        
        // alert end of connection phase
        /*
        NSString *str = [NSString stringWithFormat:@"Connected with %@",[mySession displayNameForPeer:peerID]];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
        */
        /*
        NSString *str = [NSString stringWithFormat:@"Connected with %@, Time delay is %f",[mySession displayNameForPeer:peerID], (self.totalTime/2)];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
        */
        
        //[NSThread sleepForTimeInterval:2.5];
        // notify viewControllerDelegate that connection was established
        //if ([self.viewDelegate respondsToSelector:@selector(endedConnectionPhase)]){
        //    [self.viewDelegate endedConnectionPhase];
        //}
        
	}
	
}

@end
