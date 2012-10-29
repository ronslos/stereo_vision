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

/*
 Method      : viewDidLoad
 Parameters  : 
 Returns     :
 Description : This method gets called automatically when this view controller is loaded to the screen.
 It is used to initialize all the objects required for the functionality of this view.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // getting the handle for the session object
    _sessionManager = [SessionManager instance];
    if (_sessionManager.mySession != NULL)
    {
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
    
    // setting the functionality of the UITextField objects
    [self.squareHeight setReturnKeyType:UIReturnKeyDone];
    [self.squareWidth setReturnKeyType:UIReturnKeyDone];
    [self.boardWidth setReturnKeyType:UIReturnKeyDone];
    [self.boardHeight setReturnKeyType:UIReturnKeyDone];
    [self.squareHeight setDelegate:self];
    [self.squareWidth setDelegate:self];
    [self.boardHeight setDelegate:self];
    [self.boardWidth setDelegate:self];
    
    // loading the stored values for the chessboard charicteristic 
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
    
    // loading the stored matrices that resulted from the last stereo calibration process
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

/*
 Method      : viewDidUnload
 Parameters  : 
 Returns     :
 Description : This method gets called automatically after this view controller is taken of the screen.
               It is not called immediately, rather at an undetermined time.
               It is used to release all the objects that were held by this viewcontroller.
 */
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
 Method      : viewWillDisappear
 Parameters  : 
 Returns     :
 Description : This method gets called automatically just as this view controller is taken of the screen.
               Used to perform tasks that must be done at the moment this view is being removed.
 */
-(void) viewWillDisappear:(BOOL)animated 
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // if back button was pressed, notify other device to move back as well
        if (_sessionManager.mySession != NULL) {
            [_sessionManager sendMoveBackToMenu];
        }
    }
    [super viewWillDisappear:animated];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{
    [textField resignFirstResponder];
    return NO;
}

/*
 Method      : saveWidth
 Parameters  : (UITextField *)sender
 Returns     :
 Description : Action that is activated when editing was finished in the board width field - number of internal corners horizontally.
               Stores the new value, and if there's an active session also sends it to the other device.
 */
- (IBAction)saveWidth:(UITextField *)sender 
{
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardWidth"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new board width data to other device
        [_sessionManager settingsUpdate:@"boardWidth:" withValue:sender.text];
    }
}

/*
 Method      : saveHeight
 Parameters  : (UITextField *)sender
 Returns     :
 Description : Action that is activated when editing was finished in the board height field - number of internal corners vertically.
               Stores the new value, and if there's an active session also sends it to the other device.
 */
- (IBAction)saveHeight:(UITextField *)sender 
{
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"boardHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new board height data to other device
        [_sessionManager settingsUpdate:@"boardHeight:" withValue:sender.text];
    }
}

/*
 Method      : saveSquareHeight
 Parameters  : (UITextField *)sender
 Returns     :
 Description : Action that is activated when editing was finished in the board square height field.
               Stores the new value, and if there's an active session also sends it to the other device.
 */
- (IBAction)saveSquareHeight:(UITextField *)sender 
{
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"squareHeight"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new square height data to other device
        [_sessionManager settingsUpdate:@"squareHeight:" withValue:sender.text];
    }

}

/*
 Method      : saveSquareWidth
 Parameters  : (UITextField *)sender
 Returns     :
 Description : Action that is activated when editing was finished in the board square width field.
               Stores the new value, and if there's an active session also sends it to the other device.
 */
- (IBAction)saveSquareWidth:(UITextField *)sender 
{
    [[NSUserDefaults standardUserDefaults] setObject: sender.text forKey:@"squareWidth"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (_sessionManager.mySession != NULL) {
        // send new square width data to other device
        [_sessionManager settingsUpdate:@"squareWidth:" withValue:sender.text];
    }

}

/*
 Method      : LeftRightControlChanged
 Parameters  : (UISegmentedControl*)sender
 Returns     :
 Description : Action that is activated when the state of the control button was changed.
               Stores the new relative location - left or right, and if there's an active session also sends 
               the opposite location to the other device.
 */
- (IBAction)LeftRightControlChanged:(UISegmentedControl*)sender 
{
    if ([sender selectedSegmentIndex]==0) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"Left"] forKey:@"side"];
        if (_sessionManager.mySession != NULL) {
            // send new relative location data to other device
            [_sessionManager settingsUpdate:@"side:" withValue:[NSString stringWithFormat:@"Right"]];
        }
    }
    else if ([sender selectedSegmentIndex]==1) {
        [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat:@"Right"] forKey:@"side"];
        if (_sessionManager.mySession != NULL) {
            // send new relative location data to other device
            [_sessionManager settingsUpdate:@"side:" withValue:[NSString stringWithFormat:@"Left"]];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

/*
 Method      : receiveData
 Parameters  : (NSData *)data - the data received in the message
               (NSString *)peer  - the peer sending us this data
               (GKSession *)session - the session this peer belongs to
 Returns     :
 Description : This function gets called when a message is being received from the other device, and this view controller
               is set as the data receive handler.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{   
    NSString *whatDidIget = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (![whatDidIget caseInsensitiveCompare:@"move to menu"])
    {
        // need to move back to main menu
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if ([whatDidIget hasPrefix:@"boardWidth:"])
    {
        // update board width value
        NSString* value = [whatDidIget substringFromIndex:11];
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"boardWidth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.boardWidth setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"boardHeight:"])
    {
        // update board height value
        NSString* value = [whatDidIget substringFromIndex:12];
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"boardHeight"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.boardHeight setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"squareHeight:"])
    {
        // update square height value
        NSString* value = [whatDidIget substringFromIndex:13];
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"squareHeight"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.squareHeight setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"squareWidth:"])
    {
        // update square width value
        NSString* value = [whatDidIget substringFromIndex:12];
        [[NSUserDefaults standardUserDefaults] setObject: value forKey:@"squareWidth"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.squareWidth setText:value]; 
    }
    else if ([whatDidIget hasPrefix:@"side:"])
    {
        // update the relative position of the device
        NSString* value = [whatDidIget substringFromIndex:5];
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
