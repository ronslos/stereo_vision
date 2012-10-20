//
//  Isgl3dViewController.m
//  pointCloud
//
//  Created by Ron Slossberg on 10/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Isgl3dViewController.h"


@implementation Isgl3dViewController

@synthesize vertices = _vertices;
@synthesize vertexNumber = _vertexNumber;


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	isgl3dAllowedAutoRotations allowedAutoRotations = [Isgl3dDirector sharedInstance].allowedAutoRotations;
	if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationNone) {
		return NO;
	
	} else if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByIsgl3dDirector) {
		
		if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationLandscapeRight;
	
		} else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationLandscapeLeft;
	
		} else if (interfaceOrientation == UIInterfaceOrientationPortrait && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationPortrait;
	
		} else if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationPortraitUpsideDown;
		}
	
		// Return true only for portrait
		return  (interfaceOrientation == UIInterfaceOrientationPortrait);

	} else if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByUIViewController) {
		if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && allowedAutoRotations != Isgl3dAllowedAutoRotationsPortraitOnly) {
			return YES;
			
		} else if (UIInterfaceOrientationIsPortrait(interfaceOrientation) && allowedAutoRotations != Isgl3dAllowedAutoRotationsLandscapeOnly) {
			return YES;
			
		} else {
			return NO;
		}
		
	} else {
		NSLog(@"Isgl3dViewController:: ERROR : Unknown auto rotation strategy of Isgl3dDirector.");
		return NO;
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if ([Isgl3dDirector sharedInstance].autoRotationStrategy == Isgl3dAutoRotationByUIViewController) {
		CGRect screenRect = [[UIScreen mainScreen] bounds];
		CGRect rect = CGRectZero;
		
		if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {		
			rect = screenRect;
		
		} else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			rect.size = CGSizeMake( screenRect.size.height, screenRect.size.width );
		}
		
		UIView * glView = [Isgl3dDirector sharedInstance].openGLView;
		float contentScaleFactor = [Isgl3dDirector sharedInstance].contentScaleFactor;
		
		if (contentScaleFactor != 1) {
			rect.size.width *= contentScaleFactor;
			rect.size.height *= contentScaleFactor;
		}
		glView.frame = rect;
	}	
}

- (void) viewDidLoad{
	
    [super viewDidLoad];
    
    _sessionManager = [SessionManager instance];
    if (_sessionManager.mySession != NULL)
    {
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
    
	// Instantiate the Isgl3dDirector and set background color
	[Isgl3dDirector sharedInstance].backgroundColorString = @"333333ff";
    
	// Set the device orientation
	[Isgl3dDirector sharedInstance].deviceOrientation = Isgl3dOrientationLandscapeLeft;
    
	// Set the director to display the FPS
	[Isgl3dDirector sharedInstance].displayFPS = YES;
    
	// Create the UIViewController
	//Isgl3dViewController* _viewController = [[Isgl3dViewController alloc] initWithNibName:nil bundle:nil];
	self.wantsFullScreenLayout = YES;
	
	// Create OpenGL view (here for OpenGL ES 1.1)
	Isgl3dEAGLView * glView = [Isgl3dEAGLView viewWithFrameForES1:[[self view] bounds]];
    
	// Set view in director
	[Isgl3dDirector sharedInstance].openGLView = glView;
	
	// Specify auto-rotation strategy if required (for example via the UIViewController and only landscape)
	[Isgl3dDirector sharedInstance].autoRotationStrategy = Isgl3dAutoRotationByUIViewController;
	[Isgl3dDirector sharedInstance].allowedAutoRotations = Isgl3dAllowedAutoRotationsLandscapeOnly;
	
	// Enable retina display : uncomment if desired
    	[[Isgl3dDirector sharedInstance] enableRetinaDisplay:YES];
    
	// Enables anti aliasing (MSAA) : uncomment if desired (note may not be available on all devices and can have performance cost)
    	[Isgl3dDirector sharedInstance].antiAliasingEnabled = YES;
	
	// Set the animation frame rate
	[[Isgl3dDirector sharedInstance] setAnimationInterval:1.0/60];
    
	// Add the OpenGL view to the view controller
	self.view = glView;
    
	// Add view to window and make visible
//	[_window addSubview:_viewController.view];
//	[_window makeKeyAndVisible];
    
	// Creates the view(s) and adds them to the director
    _depthView = [DepthView view];
    [_depthView setVertices:_vertices];
    [_depthView createScene];
	[[Isgl3dDirector sharedInstance] addView:_depthView];
	// Run the director
    [[Isgl3dDirector sharedInstance] run];
    //[[Isgl3dDirector sharedInstance]startAnimation];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[[Isgl3dDirector sharedInstance].openGLView removeFromSuperview];
	
	// End and reset the director

    //[[Isgl3dDirector sharedInstance] pause];
    [self setVertices:nil];
    
    [Isgl3dDirector resetInstance];
    [_depthView destroyScene];
    //_depthView = nil;


}

- (void) viewDidDisappear:(BOOL)animated {
    //[Isgl3dDirector resetInstance];
}

- (void) viewDidUnload {
    	[super viewDidUnload];
}

- (void) didReceiveMemoryWarning {
    [[Isgl3dDirector sharedInstance] onMemoryWarning];
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    // this function does NOTHING in this view controller
    
    // session manager control was added here as a patch to handle the case in which one device returns from the photo library to the main 
    // menu, and the other device is still watching a photo.
    // In that case, we don't want the second device to be pulled back to the main menu as well.
    // Therefore, we set this view controller to be the DataReceivedHandler, but we don't react on any message that is arriving.
}

@end
