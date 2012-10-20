//
//  LibraryViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef libraryviewcontroller_h_
#define libraryviewcontroller_h_

#import <UIKit/UIKit.h>
#import "Isgl3dViewController.h"
#import "SessionManager.h"


@interface LibraryViewController : UITableViewController <GKPeerPickerControllerDelegate>
{
    SessionManager* _sessionManager;
}

@property (nonatomic, strong) NSMutableArray *pictures;

@end

#endif