//
//  DepthView.h
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef depthview_h_
#define depthview_h_

#import "isgl3d.h"
#import "Isgl3dDemoCameraController.h"
#import <UIKit/UIKit.h>

typedef struct {
    float Position[3];
    float Color[3];
} Vertex;

@interface DepthView : Isgl3dBasic3DView 
{
    // camera controller instance
    Isgl3dDemoCameraController * _cameraController;
    // node for particle system that we will add to scene
    Isgl3dParticleNode *_node;
}

// vertex data
@property (nonatomic) Vertex *vertices;
// vertex data size
@property (nonatomic) int vertexNumber;

// function for creation of scene which is called before view is loaded
-(void) createScene;
// function to destroy scene
// here it was necessary to change the code for the node object in isgl3d library to make it compatible for ARC
-(void) destroyScene;

@end

#endif

