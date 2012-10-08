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

// Override default setter of pictures to enable reloading of the table
/*
- (void) setPictures:(NSMutableArray *)pictures
{
    if (_pictures != pictures) {
        _pictures = pictures;
        [self.tableView reloadData];
    }
}
 */

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"] != NULL) {
        NSArray * savedArray = (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"pictures"];
        self.pictures = [[NSMutableArray alloc] initWithArray:savedArray];
    }
    else {
        self.pictures = [[NSMutableArray alloc] init];
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.pictures = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    // ********** need to generate num_of_cells = num of photos inside the album ***********
    return [self.pictures count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Single Image Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Single Image Cell"];
    }
    // Configure the cell...
    // ***************** need to edit the attributes of the cell according to the releavant image **
    NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];
    cell.textLabel.text = [picture objectForKey:@"name"];
    cell.detailTextLabel.text = [picture objectForKey:@"date"];
    return cell;
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];
//    NSString * url = [picture objectForKey:@"url"];
//    NSLog(@"url is %@" , url);
  //  UIImage * img = [UIImage imageWithContentsOfFile:[picture objectForKey:@"url"]];
    NSString * depthUrl = [picture objectForKey:@"depth_url"];
    NSData *data = [NSKeyedUnarchiver unarchiveObjectWithFile:depthUrl];
    Vertex* vertices = (Vertex*)[data bytes];

    //UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/IMG_%d.%@", documentsDirectoryPath, imgNum ,@"jpg"]];
    if ([segue.identifier isEqualToString:@"moveToImage"]) 
    {
        [segue.destinationViewController setVertices: vertices];
        [segue.destinationViewController setVertexNumber:[data length]/(7*sizeof(float))];

    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        NSDictionary * picture = [self.pictures objectAtIndex:indexPath.row];
        NSURL * url = [NSURL URLWithString:[picture objectForKey:@"url"]];
        NSLog(@"url is %@" , url);
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        [self.pictures removeObjectAtIndex:indexPath.row];
        NSArray * savedArray = [[NSArray alloc] initWithArray:self.pictures];
        [[NSUserDefaults standardUserDefaults] setObject:savedArray forKey:@"pictures"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [tableView reloadData];

    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ******** navigation code before showing the picture ************
    //id picture = [self.pictures objectAtIndex:indexPath.row];
    
}

@end
