//
//  ViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef viewcontroller_h_
#define viewcontroller_h_

#import <UIKit/UIKit.h>
#import "SessionManager.h"
#import "ResponseFromSession.h"


@interface ViewController : UIViewController <ResponseFromSession>
{
    SessionManager * _sessionManager;
}

- (IBAction)connectPressed;
- (IBAction)calibratePressed;
- (IBAction)reconstructPressed;
- (IBAction)photoLibraryPressed;
- (void) endedConnectionPhase;

@end

#endif