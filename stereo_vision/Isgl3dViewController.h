//
//  Isgl3dViewController.h
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef isgl3dviewcontroller_h_
#define isgl3dviewcontroller_h_

#import <UIKit/UIKit.h>
#import "SessionManager.h"
#import "DepthView.h"
#import "isgl3d.h"


@interface Isgl3dViewController : UIViewController <GKPeerPickerControllerDelegate>
{
    // depth view controller instance
    DepthView* _depthView;
    // instance of session manager
    SessionManager* _sessionManager;
}

// vertex data
@property (nonatomic) Vertex *vertices;
// size of vertex data
@property (nonatomic) int vertexNumber;

@end

#endif