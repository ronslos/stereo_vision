//
//  HelloWorldView.m
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DepthView.h"

@implementation DepthView
@synthesize vertices = _vertices;

- (id) init {
	
	self = [super init];
    return self;
}

-(void) createScene {
    // Translate the camera.
    
    _cameraController = [[Isgl3dDemoCameraController alloc] initWithCamera:self.camera andView:self];
    _cameraController.orbit=200;
//    _cameraController.theta = 30;
//    _cameraController.phi = 30;
    //_cameraController.doubleTapEnabled = NO;
//    [self.camera setPosition:iv3(0.0, 2.0, 1000.0)];
  //  [self.camera setFar:2000.0];
    
    Isgl3dTextureMaterial *  spriteMaterial = [Isgl3dTextureMaterial materialWithTextureFile:@"particle.png" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
    //		Isgl3dGLMesh * billboardMesh = [Isgl3dPlane meshWithGeometry:4 height:3 nx:2 ny:2];
    Isgl3dParticleSystem* particleSystem = [Isgl3dParticleSystem particleSystem];
    _node = [self.scene createNodeWithParticle:particleSystem andMaterial:spriteMaterial];
    _node.transparent = YES;
    [_node enableAlphaCullingWithValue:0.5];
    _node.position = iv3(0,0,0);
    _cameraController.target = _node;
    [self setSceneAmbient:@"444444"];
    Isgl3dGLParticle* particle;
    
    for (int i=0 ; i<172800 ; i+=2)
    {
         particle = [particleSystem addParticle];
        [particle setColor:_vertices[i].Color[0] g:_vertices[i].Color[1] b:_vertices[i].Color[2] a:1.0];
//        printf("r channel :%f\n",_vertices[i].Color[0]);
//        printf("g channel :%f\n",_vertices[i].Color[1]);
//        printf("b channel :%f\n",_vertices[i].Color[2]);
        [particle setX:_vertices[i].Position[0]];
        [particle setY:_vertices[i].Position[1]];
        [particle setZ:_vertices[i].Position[2]+400.0];
        [particle setSize:4.0];
    }
    
    
    [self schedule:@selector(tick:)];
}

- (void) onActivated {
	// Add camera controller to touch-screen manager
	[[Isgl3dTouchScreen sharedInstance] addResponder:_cameraController];
}

- (void) onDeactivated {
	// Remove camera controller from touch-screen manager
    [[Isgl3dTouchScreen sharedInstance] removeResponder:_cameraController];
}

- (void) tick:(float)dt {
	
	// update camera
    [_cameraController update];
}


-(void) destroyScene{
    //[self setVertices:nil];
    //[self setScene:nil];
//    [[Isgl3dTouchScreen sharedInstance] removeResponder:_cameraController];
//    _cameraController = nil;
    [_node destroyNode];
    
}

@end

