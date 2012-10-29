//
//  ResponseFromSession.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// this protocol is required by the view controller that creates a new session between the devices,
// in order to get notified from the SessionManager class when the session was established.

@protocol ResponseFromSession <NSObject>

- (void) endedConnectionPhase;

@end
