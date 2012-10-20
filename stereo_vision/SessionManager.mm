//
//  SessionManager.m
//  3d_visioin
//
//  Created by Ron Slossberg on 4/30/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "SessionManager.h"

@interface SessionManager ()

@property (nonatomic) double start;
@property (nonatomic) double interval;
@property (nonatomic) double rttTime;
@property (nonatomic, strong) NSMutableArray * rttVals;

@end

@implementation SessionManager

@synthesize mySession;
@synthesize start = _start;
@synthesize interval = _interval;
@synthesize rttTime = _rttTime;
@synthesize viewDelegate = _viewDelegate;
@synthesize rttVals = _rttVals;

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

- (void) sendDisableCapture: (id) sender
{
    NSString *str = @"disableCapture";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendEnableCapture: (id) sender
{
    NSString *str = @"enableCapture";
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

- (void) sendMoveToSettings: (id) sender
{
    NSString *str = @"move to settings";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendMoveToLibrary: (id) sender 
{
    NSString *str = @"move to library";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendMoveBackToMenu
{
    NSString *str = @"move to menu";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendCalculateTimeDelay: (id) sender
{
    // prepare for sending timestamp message
    // self.start = [NSDate date]
    self.start = CACurrentMediaTime();
    
    NSString *str = @"calculate time delay";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendCalculateTimeDelayResponse: (id) sender
{
    NSString *str = @"calculate time delay response";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendUpdateDelay: (id) sender
{
    NSString *str = @"update delay";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) sendUpdateDelayResponse: (id) sender
{
    NSString *str = @"update delay response";
	[mySession sendDataToAllPeers:[str dataUsingEncoding: NSASCIIStringEncoding] withDataMode:GKSendDataReliable error:nil];
}

- (void) settingsUpdate: (NSString*) field withValue: (NSString*) value
{
    NSString* str = field;
    str = [str stringByAppendingString:value];
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
        [self sendCalculateTimeDelayResponse: self];
        
        // patch in case the other device missed your first message
        if (_count == 0) {
            _gapCount++;
            if (_gapCount > 3){
                [self sendCalculateTimeDelay: self];
            }
        }
    }
    else if (![whatDidIget caseInsensitiveCompare:@"calculate time delay response"])
    {
        self.interval = CACurrentMediaTime();
        self.rttTime = self.interval - self.start;
        NSNumber * val = [NSNumber numberWithDouble:self.rttTime];
        [self.rttVals insertObject:val atIndex:_count];
        _count++;
        if (_count == 10) {
            if ([self.viewDelegate respondsToSelector:@selector(endedConnectionPhase)]){
                [self.viewDelegate endedConnectionPhase];
            }
            double totalDelay = [TimeDelayCalculation calculateInitialDelay:self.rttVals];
            NSNumber * delay = [NSNumber numberWithDouble:totalDelay];
            [[NSUserDefaults standardUserDefaults] setObject:delay forKey:@"timeDelay"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *str = [NSString stringWithFormat:@"with time delay of %f sec", (totalDelay)];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connected" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else {
            // send another timestamp message
            [self sendCalculateTimeDelay: self];
        }
        
    }
    else {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Received" message:whatDidIget delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
    }
    
}

#pragma mark -
#pragma mark GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
    
	if (state == GKPeerStateConnected){
		// Add the peer to the Array
		[peers addObject:peerID];
        
		// Used to acknowledge that we will be sending data
		[mySession setDataReceiveHandler:self withContext:nil];
        
        // calculate the time delay between the devices
        _count = 0;
        _gapCount = 0;
        self.rttVals = [NSMutableArray arrayWithCapacity:10];
        [NSThread sleepForTimeInterval:1];
        [self sendCalculateTimeDelay: self];
	}
	
}
@end
