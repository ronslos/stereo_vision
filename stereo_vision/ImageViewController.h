//
//  3DImageViewController.h
//  stereo_vision
//
//  Created by Omer Shaked on 9/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImage * image;
@property (strong, nonatomic) NSString* imgName;

@end
