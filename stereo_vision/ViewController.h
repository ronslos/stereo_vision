//
//  ViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SessionManager.h"

@interface ViewController : UIViewController

{
    SessionManager * _sessionManager;
}

- (IBAction)connectPressed;
- (IBAction)calibratePressed;
- (IBAction)reconstructPressed;

@end
