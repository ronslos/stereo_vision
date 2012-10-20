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
    Isgl3dDemoCameraController * _cameraController;
    Isgl3dParticleNode *_node;
    float _camCoord[3];
}

@property (nonatomic) Vertex *vertices;

-(void) createScene;
-(void) destroyScene;

@end

#endif

