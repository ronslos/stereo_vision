//
//  HelloGLKitViewController.h
//  HelloGLKit
//
//  Created by Ray Wenderlich on 9/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>
typedef struct {
    float Position[3];
    float Color[4];
} Vertex;
@interface glViewController : GLKViewController{
}

@property (nonatomic) Vertex *vertices;
@property (nonatomic) int vertexNumber;

@end
