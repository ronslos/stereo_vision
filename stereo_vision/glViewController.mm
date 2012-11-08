//
//  HelloGLKitViewController.m
//  HelloGLKit
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "glViewController.h"
//#include "vertices.h"
#include <iostream>


//const Vertex Vertices[] = {
//    // Front
//    {{1, -1, 1}, {1, 0, 0, 1}},
//    {{1, 1, 1}, {0, 1, 0, 1}},
//    {{-1, 1, 1}, {0, 0, 1, 1}},
//    {{-1, -1, 1}, {0, 0, 0, 1}},
//    // Back
//    {{1, 1, -1}, {1, 0, 0, 1}},
//    {{-1, -1, -1}, {0, 1, 0, 1}},
//    {{1, -1, -1}, {0, 0, 1, 1}},
//    {{-1, 1, -1}, {0, 0, 0, 1}},
//    // Left
//    {{-1, -1, 1}, {1, 0, 0, 1}},
//    {{-1, 1, 1}, {0, 1, 0, 1}},
//    {{-1, 1, -1}, {0, 0, 1, 1}},
//    {{-1, -1, -1}, {0, 0, 0, 1}},
//    // Right
//    {{1, -1, -1}, {1, 0, 0, 1}},
//    {{1, 1, -1}, {0, 1, 0, 1}},
//    {{1, 1, 1}, {0, 0, 1, 1}},
//    {{1, -1, 1}, {0, 0, 0, 1}},
//    // Top
//    {{1, 1, 1}, {1, 0, 0, 1}},
//    {{1, 1, -1}, {0, 1, 0, 1}},
//    {{-1, 1, -1}, {0, 0, 1, 1}},
//    {{-1, 1, 1}, {0, 0, 0, 1}},
//    // Bottom
//    {{1, -1, -1}, {1, 0, 0, 1}},
//    {{1, -1, 1}, {0, 1, 0, 1}},
//    {{-1, -1, 1}, {0, 0, 1, 1}},
//    {{-1, -1, -1}, {0, 0, 0, 1}}
//};


//const GLushort Indices[] = {
//    // Front
//    0, 1, 2,
//    2, 3, 0,
//    // Back
//    4, 6, 5,
//    4, 5, 7,
//    // Left
//    8, 9, 10,
//    10, 11, 8,
//    // Right
//    12, 13, 14,
//    14, 15, 12,
//    // Top
//    16, 17, 18,
//    18, 19, 16,
//    // Bottom
//    20, 21, 22,
//    22, 23, 20
//};

@interface glViewController () {
    float _curRed;
    BOOL _increasing;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    float _rotation;
    GLKMatrix4 _rotMatrix;
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
    BOOL _slerping;
    float _slerpCur;
    float _slerpMax;
    GLKQuaternion _slerpStart;
    GLKQuaternion _slerpEnd;
    GLuint* _indices;
    float _zoom;
    float _avX, _avY , _avZ;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation glViewController
@synthesize context = _context;
@synthesize effect = _effect;
@synthesize vertices = _vertices;
@synthesize vertexNumber = _vertexNumber;

// Rest of file...

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */
    


//    - (void)setupGL {
//        int i;
//        for (i=0; i<_vertexNumber; i++) {
//            std::cout << "{{" << _vertices[i].Position[0] <<"," << _vertices[i].Position[1] <<","<< _vertices[i].Position[2] <<"}, {"<< _vertices[i].Color[0] <<"," << _vertices[i].Color[1]  << "," << _vertices[i].Color[2] <<","<< _vertices[i].Color[3] << " }}," << std::endl;
//        }
        
- (void)setupGL {
    
    _avX = 0;
    _avY = 0;
    _avZ = 0;
    int i;
    for (i=0 ; i<_vertexNumber ; i++){
        // find average particle position inorder to center the particles in the view
        _avX += _vertices[i].Position[0]/_vertexNumber;
        _avY += _vertices[i].Position[1]/_vertexNumber;
        _avZ += _vertices[i].Position[2]/_vertexNumber;
    }
    for (i=0 ; i<_vertexNumber ; i++)
    {
        _vertices[i].Position[0]-=_avX;
        _vertices[i].Position[1]-=_avY;
        _vertices[i].Position[2]-=_avZ;
    }
    
    

    _indices = (GLuint*) malloc(sizeof(GLuint)*_vertexNumber*6);
    int _ny = 360;
    int _nx = 480;
    int index = 0;
    int bla;
    for (int i = 0; i < _nx-1; i++) {
        for (int j = 0; j < _ny-1; j++) {
            
            
            int first = i * (_ny ) + j;
            int second = first + (_ny );
            int third = first + 1;
            int fourth = second + 1;
            
            //                NSLog(@"%d %d %d %d %d %d", first,third,second, third, fourth, second);
            
            _indices[index++] = first;
            _indices[index++] = third;
            _indices[index++] = second;
            
            _indices[index++] = third;
            _indices[index++] = fourth;
            _indices[index++] = second;
            
            //std::cout << first <<"," << third <<"," << second <<"," << third <<"," << fourth <<"," << second <<","<< std::endl;
        }
    }

    _zoom=-1000;
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_CULL_FACE);
    
    self.effect = [[GLKBaseEffect alloc] init];

    
    // New lines
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Old stuff
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _vertexNumber*sizeof(float)*7, _vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _vertexNumber*sizeof(GLuint)*6, _indices, GL_STATIC_DRAW);
    
    // New lines (were previously in draw)
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));

    
    // New line
    glBindVertexArrayOES(0);
    
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
    
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];
    
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    
    _slerping = YES;
    _slerpCur = 0;
    _slerpMax = 1.0;
    _slerpStart = _quat;
    _slerpEnd = GLKQuaternionMake(0, 0, 0, 1);
    
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    free(_indices);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    self.view.multipleTouchEnabled=YES;
    view.context = self.context;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    [self setupGL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(_curRed, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    [self.effect prepareToDraw];
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, _vertexNumber*6, GL_UNSIGNED_INT, 0);
//    glDrawArrays(GL_TRIANGLES, 0, sizeof(Indices)/sizeof(Indices[0]));
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
//    if (_increasing) {
//        _curRed += 1.0 * self.timeSinceLastUpdate;
//    } else {
//        _curRed -= 1.0 * self.timeSinceLastUpdate;
//    }
//    if (_curRed >= 1.0) {
//        _curRed = 1.0;
//        _increasing = NO;
//    }
//    if (_curRed <= 0.0) {
//        _curRed = 0.0;
//        _increasing = YES;
//    }
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 1000.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
//    _zoom+=2.f;
//    NSLog(@"%f",_zoom);
    //    _rotation += 90 * self.timeSinceLastUpdate;
    //    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(25), 1, 0, 0);
    //    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 0);
    //    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, _rotMatrix);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    if (_slerping) {
        
        _slerpCur += self.timeSinceLastUpdate;
        float slerpAmt = _slerpCur / _slerpMax;
        if (slerpAmt > 1.0) {
            slerpAmt = 1.0;
            _slerping = NO;
        }
        
        _quat = GLKQuaternionSlerp(_slerpStart, _slerpEnd, slerpAmt);
    }
    
}

- (GLKVector3) projectOntoSurface:(GLKVector3) touchPoint
{
    float radius = self.view.bounds.size.width/3;
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    GLKVector3 P = GLKVector3Subtract(touchPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else
    {
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
    //    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
    //    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
    //    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
    //    self.paused = !self.paused;
    if ([touches count] == 1){
        
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    NSEnumerator * enumerator = [touches objectEnumerator];
    UITouch * touch1 = [enumerator nextObject];
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    if ([touches count] == 2) {
        UITouch * touch2 = [enumerator nextObject];
        
        CGPoint location2 = [touch2 locationInView:self.view];
        CGPoint	previousLocation1 = [touch previousLocationInView:self.view];
        CGPoint	previousLocation2 = [touch2 previousLocationInView:self.view];
        
        
        float previousDistance = [self distanceBetweenPoint1:previousLocation1 andPoint2:previousLocation2];
        float currentDistance = [self distanceBetweenPoint1:location andPoint2:location2];
        
        float changeInDistance = currentDistance - previousDistance;
        _zoom+= changeInDistance;
    }
    else if ([touches count] ==1) {
        float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
        float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
        bool isInvertible;
        GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),GLKVector3Make(1, 0, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
        GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),GLKVector3Make(0, 1, 0));
        _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
        _current_position = GLKVector3Make(location.x, location.y, 0);
        _current_position = [self projectOntoSurface:_current_position];
        [self computeIncremental];
    }


    
}
- (float) distanceBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2 {
	float dx = point1.x - point2.x;
	float dy = point1.y - point2.y;
	
	return sqrt(dx*dx + dy*dy);
}



- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
    
}

@end
