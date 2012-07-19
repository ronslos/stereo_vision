//
//  SettingsViewController.h
//  3d_visioin
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "UIImage+OpenCV.h"
#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
- (IBAction)saveWidth:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *boardWidth;
- (IBAction)saveHeight:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *boardHeight;
- (IBAction)saveSquareLength:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *squareLength;
@property (weak, nonatomic) IBOutlet UILabel *R1_1;
@property (weak, nonatomic) IBOutlet UILabel *R1_2;
@property (weak, nonatomic) IBOutlet UILabel *R1_3;
@property (weak, nonatomic) IBOutlet UILabel *R2_1;
@property (weak, nonatomic) IBOutlet UILabel *R2_2;
@property (weak, nonatomic) IBOutlet UILabel *R2_3;
@property (weak, nonatomic) IBOutlet UILabel *R3_1;
@property (weak, nonatomic) IBOutlet UILabel *R3_2;
@property (weak, nonatomic) IBOutlet UILabel *R3_3;
@property (weak, nonatomic) IBOutlet UILabel *T1_1;
@property (weak, nonatomic) IBOutlet UILabel *T2_1;
@property (weak, nonatomic) IBOutlet UILabel *T3_1;

// complete connections of the other labels

@end
