//
//  SettingsViewController.h
//  3d_visioin
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "UIImage+OpenCV.h"
#import <UIKit/UIKit.h>
#import "SessionManager.h"

@interface SettingsViewController : UIViewController <UITextFieldDelegate, GKPeerPickerControllerDelegate>
{
    SessionManager* _sessionManager;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
- (IBAction)saveWidth:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *boardWidth;
- (IBAction)saveHeight:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *boardHeight;
- (IBAction)saveSquareHeight:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *squareHeight;
- (IBAction)saveSquareWidth:(UITextField *)sender;
@property (weak, nonatomic) IBOutlet UITextField *squareWidth;
- (IBAction)LeftRightControlChanged:(UISegmentedControl*)sender;

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
@property (weak, nonatomic) IBOutlet UILabel *E1_1;
@property (weak, nonatomic) IBOutlet UILabel *E1_2;
@property (weak, nonatomic) IBOutlet UILabel *E1_3;
@property (weak, nonatomic) IBOutlet UILabel *E2_1;
@property (weak, nonatomic) IBOutlet UILabel *E2_2;
@property (weak, nonatomic) IBOutlet UILabel *E2_3;
@property (weak, nonatomic) IBOutlet UILabel *E3_1;
@property (weak, nonatomic) IBOutlet UILabel *E3_2;
@property (weak, nonatomic) IBOutlet UILabel *E3_3;
@property (weak, nonatomic) IBOutlet UILabel *F1_1;
@property (weak, nonatomic) IBOutlet UILabel *F1_2;
@property (weak, nonatomic) IBOutlet UILabel *F1_3;
@property (weak, nonatomic) IBOutlet UILabel *F2_1;
@property (weak, nonatomic) IBOutlet UILabel *F2_2;
@property (weak, nonatomic) IBOutlet UILabel *F2_3;
@property (weak, nonatomic) IBOutlet UILabel *F3_1;
@property (weak, nonatomic) IBOutlet UILabel *F3_2;
@property (weak, nonatomic) IBOutlet UILabel *F3_3;
@property (weak, nonatomic) IBOutlet UISegmentedControl *LeftRightControl;

@end
