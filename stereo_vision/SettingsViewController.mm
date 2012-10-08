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
@synthesize squareHeight;
@synthesize scrollView;
@synthesize boardWidth;
@synthesize boardHeight;
@synthesize squareWidth;
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
@synthesize E1_1;
@synthesize E1_2;
@synthesize E1_3;
@synthesize E2_1;
@synthesize E2_2;
@synthesize E2_3;
@synthesize E3_1;
@synthesize E3_2;
@synthesize E3_3;
@synthesize F1_1;
@synthesize F1_2;
@synthesize F1_3;
@synthesize F2_1;
@synthesize F2_2;
@synthesize F2_3;
@synthesize F3_1;
@synthesize F3_2;
@synthesize F3_3;
@synthesize LeftRightControl;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setting the UIScrollview dimensions
    //UIImage *image = [UIImage imageNamed:@"grey_img.jpeg"];
    //UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    //[scrollView addSubview:iv];
    //scrollView.contentSize = iv.bounds.size;
    
    _sessionManager = [SessionManager instance];
    if (_sessionManager.mySession != NULL)
    {
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
    
    [self.squareHeight setReturnKeyType:UIReturnKeyDone];
    [self.squareWidth setReturnKeyType:UIReturnKeyDone];
    [self.boardWidth setReturnKeyType:UIReturnKeyDone];
    [self.boardHeight setReturnKeyType:UIReturnKeyDone];
    [self.squareHeight setDelegate:self];
    [self.squareWidth setDelegate:self];
    [self.boardHeight setDelegate:self];
    [self.boardWidth setDelegate:self];
    
    NSString* boardWidthString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"boardWidth"];
    NSString* boardHeightString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"boardHeight"];
    NSString* squareHeightString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"squareHeight"];
    NSString* squareWidthString = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"squareWidth"];
    NSString* side = (NSString*) [[NSUserDefaults standardUserDefaults] objectForKey:@"side"];
    
    [self.boardWidth setText:boardWidthString];
    [self.boardHeight setText:boardHeightString];
    [self.squareHeight setText:squareHeightString];
    [self.squareWidth setText:squareWidthString];
    [self.LeftRightControl setSelectedSegmentIndex:[side hasPrefix:@"Left"]? 0 : 1];
    
    [self.scrollView setContentSize:CGSizeMake(320, 700)];
    
    // Upload from memory the settings that are stored
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
    [self setE1_1:nil];
    [self setE1_2:nil];
    [self setE1_3:nil];
    [self setE2_1:nil];
    [self setE2_2:nil];
    [self setE2_3:nil];
    [self setE3_1:nil];
    [self setE3_2:nil];
    [self setE3_3:nil];
    [self setF1_1:nil];
    [self setF1_2:nil];
    [self setF1_3:nil];
    [self setF2_1:nil];
    [self setF2_2:nil];
    [self setF2_3:nil];
    [self setF3_1:nil];
    [self setF3_2:nil];
    [self setF3_3:nil];
    [self setSquareWidth:nil];
    [self setSquareHeight:nil];
    [self setLeftRightControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.  
        if (_sessionManager.mySession != NULL) {
            [_sessionManager sendMoveBackToMenu];
        }
    }
    [super viewWillDisappear:animated];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)saveWidth:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardWidth"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new board width data to other device
        [_sessionManager settingsUpdate:@"boardWidth:" withValue:sender.text];
    }
}

- (IBAction)saveHeight:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new board height data to other device
        [_sessionManager settingsUpdate:@"boardHeight:" withValue:sender.text];
    }
}

- (IBAction)saveSquareHeight:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"squareHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new square height data to other device
        [_sessionManager settingsUpdate:@"squareHeight:" withValue:sender.text];
    }

}

- (IBAction)saveSquareWidth:(UITextField *)sender {
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"squareWidth"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new square width data to other device
        [_sessionManager settingsUpdate:@"squareWidth:" withValue:sender.text];
    }

}

- (IBAction)LeftRightControlChanged:(UISegmentedControl*)sender {
    if ([sender selectedSegmentIndex]==0) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"Left"] forKey:@"side"];
        if (_sessionManager.mySession != NULL) {
            // send new square width data to other device
            [_sessionManager settingsUpdate:@"side:" withValue:[NSString stringWithFormat:@"Right"]];
        }
    }
    else if ([sender selectedSegmentIndex]==1) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"Right"] forKey:@"side"];
        if (_sessionManager.mySession != NULL) {
            // send new square width data to other device
            [_sessionManager settingsUpdate:@"side:" withValue:[NSString stringWithFormat:@"Left"]];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if ([whatDidIget hasPrefix:@"boardWidth:"])
    {
        NSString* value = [whatDidIget substringFromIndex:11];
        NSLog(@"value is %d", [value integerValue]); // debug
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"boardWidth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.boardWidth setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"boardHeight:"])
    {
        NSString* value = [whatDidIget substringFromIndex:12];
        NSLog(@"value is %d", [value intValue]); // debug
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"boardHeight"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.boardHeight setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"squareHeight:"])
    {
        NSString* value = [whatDidIget substringFromIndex:13];
        NSLog(@"value is %d", [value integerValue]); // debug
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"squareHeight"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.squareHeight setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"squareWidth:"])
    {
        NSString* value = [whatDidIget substringFromIndex:12];
        NSLog(@"value is %d", [value integerValue]); // debug
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"squareWidth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.squareWidth setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"side:"])
    {
        NSString* value = [whatDidIget substringFromIndex:5];
        NSLog(@"value is %d", [value integerValue]); // debug
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"side"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if ([value hasPrefix:@"Left"]){
            [LeftRightControl setSelectedSegmentIndex:0];
        }
        else if ([value hasPrefix:@"Right"]){
            [LeftRightControl setSelectedSegmentIndex:1];
        }
    }
}


@end
