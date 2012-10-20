//
//  Isgl3dDemoCameraController.h
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef isgldemocameracontroller_h_
#define isgldemocameracontroller_h_

#import "isgl3d.h"


@interface Isgl3dDemoCameraController : NSObject <Isgl3dTouchScreenResponder> 
{
@private
    
	Isgl3dCamera * _camera;
	Isgl3dView * _view;
	
	Isgl3dNode * _target;
	
	float _orbit;
	float _orbitMin;
	float _vTheta;
	float _vPhi;
	float _theta;
	float _phi;	
	float _damping;
	BOOL _doubleTapEnabled;
}

@property (nonatomic, strong) Isgl3dNode * target;
@property (nonatomic) float orbit;
@property (nonatomic) float orbitMin;
@property (nonatomic) float theta;
@property (nonatomic) float phi;
@property (nonatomic) float damping;
@property (nonatomic) BOOL doubleTapEnabled;

- (id) initWithCamera:(Isgl3dCamera *)camera andView:(Isgl3dView *)view;

- (void) update;

@end

#endif