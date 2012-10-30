//
//  LibraryViewController.m
//  stereo_vision
//
//  Created by Omer Shaked on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LibraryViewController.h"

@interface LibraryViewController ()

@end

@implementation LibraryViewController

@synthesize pictures = _pictures;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    
    // loading the session handler if the session exists
    _sessionManager = [SessionManager instance];
    if (_sessionManager.mySession != NULL)
    {
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
    
    // loading the saved array of taken pictures
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"] != NULL) {
        NSArray * savedArray = (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"];
        self.pictures = [[NSMutableArray alloc] initWithArray:savedArray];
    }
    else {
        self.pictures = [[NSMutableArray alloc] init];
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
    [super viewDidUnload];
    self.pictures = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
 Method      : viewWillAppear
 Parameters  : 
 Returns     :
 Description : This method gets called automatically when an existing view controller re-appears on screen.
               Used to retreive the session data handler from the view that was removed from screen.
 */
- (void)viewWillAppear:(BOOL)animated
{
    // if a session exists - set yourself as the data receive handler
    if (_sessionManager.mySession != NULL) {
        _sessionManager = [SessionManager instance];
        [[_sessionManager mySession ] setDataReceiveHandler:self withContext:nil];
    }
    [super viewWillAppear:animated];
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
    // if back button was pressed, notify other device to move back as well
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        if (_sessionManager.mySession != NULL) {
            [_sessionManager sendMoveBackToMenu];
        }
    }
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.pictures count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set the cell for each row in the table
    static NSString *CellIdentifier = @"Single Image Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Single Image Cell"];
    }
    // Configure the cell
    NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];
    cell.textLabel.text = [picture objectForKey:@"name"];
    cell.detailTextLabel.text = [picture objectForKey:@"date"];
    
    // setting display of picture inside table view cell
    NSString * url = [picture objectForKey:@"url"];
    cell.imageView.image = [UIImage imageWithContentsOfFile:url];
    
    return cell;
}

// a cell was chosen - need to prepare the view controller we are segueing to with the correct image
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];

    NSString * depthUrl = [picture objectForKey:@"depth_url"];
    NSData *data = [NSKeyedUnarchiver unarchiveObjectWithFile:depthUrl];
    Vertex* vertices = (Vertex*)[data bytes];

    if ([segue.identifier isEqualToString:@"moveToImage"]) 
    {
        // send vertex data and number of vertices to destination view controller
        [segue.destinationViewController setVertices: vertices];
        int vertexNum = [data length]/ (3*sizeof(double));
        [segue.destinationViewController setVertexNumber:vertexNum];

    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source
        NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];
        NSURL * url = [NSURL URLWithString:[picture objectForKey:@"url"]];
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        
        // delete the records from the pictures array
        [self.pictures removeObjectAtIndex:indexPath.row];
        NSArray * savedArray = [[NSArray alloc] initWithArray:self.pictures];
        [[NSUserDefaults standardUserDefaults] setObject:savedArray forKey:@"pictures"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // reload the pictures table
        [tableView reloadData];

    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the segue is wired up directly into the tableViewCell
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
}

@end
