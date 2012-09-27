//
//  SessionManager.h
//  3d_visioin
//
//  Created by Ron Slossberg on 4/30/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#define k_Capture_Message 0;

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <QuartzCore/CAAnimation.h>
#import "ResponseFromSession.h"

@interface SessionManager : NSObject <GKSessionDelegate, GKPeerPickerControllerDelegate>
{
    //session Object
    GKSession *mySession;
    // PeerPicker Object
    GKPeerPickerController *peerPicker;
    // Array of peers connected
    NSMutableArray *peers;
    int _count;
    int _gapCount;
}

@property (nonatomic, strong) GKSession *mySession;
@property (nonatomic, weak) id<ResponseFromSession> viewDelegate;

   // Methods to connect and send data
- (void) sendDataToPeers:(id) sender WithData:(NSData*) data ;
+ (SessionManager *)instance;
- (void) initializeSession;
- (void) sendClick: (id) sender;
- (void) sendMoveToCalibration: (id) sender;
- (void) sendMoveToReconstruction: (id) sender;
- (void) sendCalculateTimeDelay;
- (void) sendCalculateTimeDelayResponse;
- (void) sendMoveBackToMenu;

@end
