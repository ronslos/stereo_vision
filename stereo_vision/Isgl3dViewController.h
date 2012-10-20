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
    DepthView* _depthView;
    SessionManager* _sessionManager;
}

@property (nonatomic) Vertex *vertices;
@property (nonatomic) int vertexNumber;

@end

#endif