//
//  SettingsViewController.mm
//  3d_visioin
//
//  Created by Ron Slossberg on 5/31/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize scrollView;
@synthesize boardWidth;
@synthesize boardHeight;
@synthesize squareLength;
@synthesize R1_1;
@synthesize R1_2;
@synthesize R1_3;
@synthesize R2_1;
@synthesize R2_2;
@synthesize R2_3;
@synthesize R3_1;
@synthesize R3_2;
@synthesize R3_3;
@synthesize T1_1;
@synthesize T2_1;
@synthesize T3_1;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.squareLength setReturnKeyType:UIReturnKeyDone];
    [self.boardWidth setReturnKeyType:UIReturnKeyDone];
    [self.boardHeight setReturnKeyType:UIReturnKeyDone];
    [self.squareLength setDelegate:self];
    [self.boardHeight setDelegate:self];
    [self.boardWidth setDelegate:self];
    
    NSString* boardWidthString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"boardWidth"];
    NSString* boardHeightString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"boardHeight"];
    NSString* squareSizeString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"squareSize"];
    
    [self.boardWidth setText:boardWidthString];
    [self.boardHeight setText:boardHeightString];
    [self.squareLength setText:squareSizeString];
    
    // Do any additional setup after loading the view from its nib.
    
    [self.scrollView setContentSize:CGSizeMake(320, 900)];
    NSMutableArray* RArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"Rarray"];
    
    NSMutableArray* TArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"Tarray"];
    
    NSMutableArray* EArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"Earray"];
    
    NSMutableArray* FArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"Farray"];
    
    NSString *text;
    
    for (int i=0; i<9; i++) {
        text = [NSString stringWithFormat:@"%.2f",[(NSNumber*)[RArray objectAtIndex:i] doubleValue ]];
        [(UILabel*) [self.scrollView viewWithTag:(i+1)] setText:text];
    }
    
    for (int i=0; i<3; i++) {
        text = [NSString stringWithFormat:@"%.2f",[(NSNumber*)[TArray objectAtIndex:i] doubleValue ]];
        [(UILabel*) [self.scrollView viewWithTag:(i+10)] setText:text];
    }
    
    for (int i=0; i<9; i++) {
        text = [NSString stringWithFormat:@"%.2f",[(NSNumber*)[EArray objectAtIndex:i] doubleValue ]];
        [(UILabel*) [self.scrollView viewWithTag:(i+13)] setText:text];
    }
    
    for (int i=0; i<9; i++) {
        text = [NSString stringWithFormat:@"%.2f",[(NSNumber*)[FArray objectAtIndex:i] doubleValue ]];
        [(UILabel*) [self.scrollView viewWithTag:(i+22)] setText:text];
    }
    
    
    
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setBoardWidth:nil];
    [self setBoardHeight:nil];
    [self setSquareLength:nil];
    [self setR1_1:nil];
    [self setR1_2:nil];
    [self setR1_3:nil];
    [self setR2_1:nil];
    [self setR2_2:nil];
    [self setR2_3:nil];
    [self setR3_1:nil];
    [self setR3_2:nil];
    [self setR3_3:nil];
    [self setT1_1:nil];
    [self setT2_1:nil];
    [self setT3_1:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)saveWidth:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardWidth"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (IBAction)saveHeight:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (IBAction)saveSquareLength:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"squareSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
