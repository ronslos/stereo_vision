//
//  ReconstructionViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SessionManager.h"

@interface ReconstructionViewController : UIViewController <GKPeerPickerControllerDelegate>
{
    SessionManager* _sessionManager;
}

@property (nonatomic) double waitPeriod;

@end
