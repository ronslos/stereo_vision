//
//  HelloGLKitViewController.m
//  HelloGLKit
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "glViewController.h"
#include <iostream>




@interface glViewController () {
    BOOL _increasing;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _depthRenderBuffer;
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
    int _numIndexes;
    int _touchCount;
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

  
- (void)setupGL {
    
    _avX = 0;
    _avY = 0;
    _avZ = 0;
    float crossNorm;
    cv::Vec3f side1, side2 , cross;
    int i , goodCount;
    for (i=0 , goodCount=0; i<_vertexNumber ; i++){
        // find average vertex position inorder to center the mesh
        if ( _vertices[i].Position[2] !=0 ){
            _avX += _vertices[i].Position[0];
            _avY += _vertices[i].Position[1];
            _avZ += _vertices[i].Position[2];
            goodCount++;
        }
    }
    _avX /= goodCount;
    _avY /= goodCount;
    _avZ /= goodCount;
    // center the mesh in view
    for (i=0 ; i<_vertexNumber ; i++)
    {
        _vertices[i].Position[0]-=_avX;
        _vertices[i].Position[1]-=_avY;
        _vertices[i].Position[2]-=_avZ;
    }
    
    // create index array
    _indices = (GLuint*) malloc(sizeof(GLuint)*_vertexNumber*6);
    int _ny = 360;
    int _nx = 480;
    _numIndexes = 0;
    for (int i = 0; i < _nx-1; i++) {
        for (int j = 0; j < _ny-1; j++) {
            
            
            int first = i * (_ny ) + j;
            int second = first + (_ny );
            int third = first + 1;
            int fourth = second + 1;
            float thresh = 15.0;
            side1 = cv::Vec3f(_vertices[first].Position[0] - _vertices[second].Position[0], _vertices[first].Position[1] - _vertices[second].Position[1] ,_vertices[first].Position[2] - _vertices[second].Position[2]);
            side2 = cv::Vec3f(_vertices[third].Position[0] - _vertices[second].Position[0], _vertices[third].Position[1] - _vertices[second].Position[1] ,_vertices[third].Position[2] - _vertices[second].Position[2]);
            cross = side1.cross(side2);
            crossNorm = cv::norm(cross);
//            NSLog(@"%f", crossNorm);

            if (crossNorm < thresh)
            {
                if( _vertices[first].Position[2]!= -_avZ && _vertices[second].Position[2]!= -_avZ && _vertices[third].Position[2]!=-_avZ){
                    _indices[_numIndexes++] = first;
                    _indices[_numIndexes++] = third;
                    _indices[_numIndexes++] = second;
                }

            }
            side1 = cv::Vec3f(_vertices[third].Position[0] - _vertices[second].Position[0], _vertices[third].Position[1] - _vertices[second].Position[1] ,_vertices[third].Position[2] - _vertices[second].Position[2]);
            side2 = cv::Vec3f(_vertices[fourth].Position[0] - _vertices[second].Position[0], _vertices[fourth].Position[1] - _vertices[second].Position[1] ,_vertices[fourth].Position[2] - _vertices[second].Position[2]);
            cross = side1.cross(side2);
            crossNorm = cv::norm(cross);
            if (crossNorm < thresh) {
                if( _vertices[fourth].Position[2]!=-_avZ && _vertices[second].Position[2]!=-_avZ && _vertices[third].Position[2]!=-_avZ){
                
                    _indices[_numIndexes++] = third;
                    _indices[_numIndexes++] = fourth;
                    _indices[_numIndexes++] = second;
                }
            }
            
        }
    }

    _zoom=-1000;
    // set EAGLContext
    [EAGLContext setCurrentContext:self.context];
    
    // create GLBaseEffect
    // this saves compiling custom shaders
    self.effect = [[GLKBaseEffect alloc] init];

    // enable depth testing
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_CULL_FACE);
    // generate and bind vertex array
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // create and bind internal vertex buffer
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER , _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _vertexNumber*sizeof(float)*7, _vertices, GL_STATIC_DRAW);
    
    // create and bind internal index buffer
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numIndexes*sizeof(GLuint), _indices, GL_STATIC_DRAW);

    
    // enable vertex and index arrays and set their pointers
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));

    
    glBindVertexArrayOES(0);
    
    // init rotMatrix and quat for later rotation
    _rotMatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatStart = GLKQuaternionMake(0, 0, 0, 1);
    
    // init tap gesture recognizer and add to view
    UITapGestureRecognizer * dtRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtRec.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtRec];
    

    
}

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    // when double tap event rotate mesh to original position
    _slerping = YES;
    _slerpCur = 0;
    _slerpMax = 1.0;
    _slerpStart = _quat;
    _slerpEnd = GLKQuaternionMake(0, 0, 0, 1);
    _touchCount-=1;
    
}

- (void)tearDownGL {
    // release all allocated memory
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    free(_indices);
    
    self.effect = nil;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // create EAGLContext and assign to self.context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    // setup GLKView
    GLKView *view = (GLKView *)self.view;
    self.view.multipleTouchEnabled=YES;
    view.context = self.context;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    _touchCount = 0;
    // call setupGL to create all buffers and arrays for drawing
    [self setupGL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // free the buffers
    [self tearDownGL];
    // release the context
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
    // background color
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    // clear color buffer and z buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindVertexArrayOES(_vertexArray);

    [self.effect prepareToDraw];
    
    glBindVertexArrayOES(_vertexArray);
    // draw mesh as GL_TRIANGLES
    glDrawElements(GL_TRIANGLES, _numIndexes, GL_UNSIGNED_INT, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
    // set projection matrix
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10000.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    // set mdelView matrix
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    // set rotation matrix
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    // multiply model view by rotation matrix
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    // set multiplied matrix to model transform matrix
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    // slerping effect while rotating
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
    // this function projects your touch onto a sphere inorder to get a good rotation response to touch
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
    // called when touche begin
    // update number of touches active
    _touchCount += [touches count];
        NSLog(@"%d",_touchCount);
    if ([touches count] == 1){
        // update anchor position and current position when touches begin
        UITouch * touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
    
        _anchor_position = GLKVector3Make(location.x, location.y, 0);
        _anchor_position = [self projectOntoSurface:_anchor_position];
    
        _current_position = _anchor_position;
        _quatStart = _quat;
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // this method is called when the user moves a finger across the screen
    NSEnumerator * enumerator = [touches objectEnumerator];
    // get reference to touches
    
    UITouch * touch = [enumerator nextObject];
    // get current and last location from touches and calculate diff
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    if (_touchCount == 2) {
        // if two finger touch change zoom according to the fingers distance change
        UITouch * touch2 = [enumerator nextObject];
        CGPoint location2 = [touch2 locationInView:self.view];
        CGPoint	previousLocation1 = [touch previousLocationInView:self.view];
        CGPoint	previousLocation2 = [touch2 previousLocationInView:self.view];
        
        
        float previousDistance = [self distanceBetweenPoint1:previousLocation1 andPoint2:previousLocation2];
        float currentDistance = [self distanceBetweenPoint1:location andPoint2:location2];
        
        float changeInDistance = currentDistance - previousDistance;
        _zoom+= changeInDistance;
        NSLog(@"%f",_zoom);
    }
    else if (_touchCount==1) {
        // if single touch calculate rotation
        float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
        float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
        // update the rotation matrix according to x and y finger movement
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

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    _touchCount -= [touches count];
    NSLog(@"%d",_touchCount);
    
}
- (float) distanceBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2 {
    // eucledean distance between points
	float dx = point1.x - point2.x;
	float dy = point1.y - point2.y;
	
	return sqrt(dx*dx + dy*dy);
}



- (void)computeIncremental {
    // calculate total quaternion rotation since beginning
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
    
}

@end
