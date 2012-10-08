//
//  Isgl3dViewController.h
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DepthView.h"
#import "isgl3d.h"



@interface Isgl3dViewController : UIViewController {
    DepthView* _depthView;
}

@property (nonatomic) Vertex *vertices;
@property (nonatomic) int vertexNumber;



@end
