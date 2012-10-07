//
//  HelloGLKitViewController.m
//  HelloGLKit
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "glViewController.h"

const Vertex Vertices[] = {
    // Front
    {{1, -1, 1}, {1, 0, 0, 1}},
    {{1, 1, 1}, {0, 1, 0, 1}},
    {{-1, 1, 1}, {0, 0, 1, 1}},
    {{-1, -1, 1}, {0, 0, 0, 1}},
    // Back
    {{1, 1, -1}, {1, 0, 0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}},
    {{1, -1, -1}, {0, 0, 1, 1}},
    {{-1, 1, -1}, {0, 0, 0, 1}},
    // Left
    {{-1, -1, 1}, {1, 0, 0, 1}},
    {{-1, 1, 1}, {0, 1, 0, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}},
    {{-1, -1, -1}, {0, 0, 0, 1}},
    // Right
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {0, 1, 0, 1}},
    {{1, 1, 1}, {0, 0, 1, 1}},
    {{1, -1, 1}, {0, 0, 0, 1}},
    // Top
    {{1, 1, 1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {0, 1, 0, 1}},
    {{-1, 1, -1}, {0, 0, 1, 1}},
    {{-1, 1, 1}, {0, 0, 0, 1}},
    // Bottom
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, -1, 1}, {0, 1, 0, 1}},
    {{-1, -1, 1}, {0, 0, 1, 1}},
    {{-1, -1, -1}, {0, 0, 0, 1}}
};
//const GLubyte Indices[] = {
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
    GLubyte *_indices;
    int _cols , _rows;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation glViewController
@synthesize context = _context;
@synthesize effect = _effect;
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

- (void)setupGL {
    
    _rows = 480;
    _cols = 360;
    
    int i= 0;
    int j=0;
    int w=0;
    _indices = (GLubyte*)malloc((_cols-1)*(_rows-1)*6*sizeof(GLubyte));

    for (j=0 ; j< _rows ; j++)
    {
        for (i=0 ; i<_cols ; i++)
        {
            if(i+1 < _rows && j+1< _cols){
                _indices[w] = _cols*j + i;
                _indices[w+1] = _cols*j + i+1;
                _indices[w+2] = _cols*(j+1) + i;
                w +=3;
                //NSLog(@"%d %d %d ",cols*j + i,cols*j + i+1,cols*(j+1) + i);
            }
            if(i-1 > 0 && j+1 < _cols)
            {
                _indices[w] = _cols*j + i;
                _indices[w+1] = _cols*(j+1) + i-1;
                _indices[w+2] = _cols*(j+1) + i;
                w +=3;
            }
//            NSLog(@"pos:%f,%f,%f" , _vertices[i+j*_cols].Position[0],_vertices[i+j*_cols].Position[1],_vertices[i+j*_cols].Position[2]);
            //NSLog(@"color:%f,%f,%f,%f" , _vertices[i+j*cols].Color[0],_vertices[i+j*cols].Color[1],_vertices[i+j*cols].Color[2],_vertices[i+j*cols].Color[3]);
        }
                
    }

    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_CULL_FACE);
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft,
                              nil];
    
    NSError * error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tile_floor" ofType:@"png"];
    GLKTextureInfo * info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (info == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    self.effect.texture2d0.name = info.name;
    self.effect.texture2d0.enabled = true;
    
    // New lines
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Old stuff
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _vertexNumber * sizeof(Vertex), _vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,6*sizeof(GLubyte), _indices, GL_STATIC_DRAW);
    
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
    //glDeleteVertexArraysOES(1, &_vertexArray);
    free(_indices);
    
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
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, 6*sizeof(GLubyte), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {

    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, -100.0f, 1000.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -10.0f);
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
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
    
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastLoc = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
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



- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
    
}

@end
