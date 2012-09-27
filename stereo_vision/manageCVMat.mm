//
//  manageCVMat.m
//  3d_visioin
//
//  Created by Ron Slossberg on 6/1/12.
//  Copyright (c) 2012 ronslos@gmail.com. All rights reserved.
//

#import "manageCVMat.h"


@implementation manageCVMat

+(void) storeCVMat: (cv::Mat) mat withKey: (NSString*) key{
    
    int matRows = mat.rows;
    int matCols = mat.cols;
    NSMutableArray *matArray = [NSMutableArray arrayWithCapacity: matRows * matCols];
    NSNumber* matElemnt;
    for (int i=0 ; i< matRows * matCols; i++)
    {
        matElemnt = [NSNumber numberWithDouble:mat.at<double>(i/matCols,i%matCols)];
        [matArray insertObject:matElemnt atIndex:i];
    }
    [[NSUserDefaults standardUserDefaults] setObject:matArray forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

+(cv::Mat) loadCVMat: (cv::Size) size  WithKey: (NSString*) key {
    
    cv::Mat result = cv::Mat::eye(size.height, size.width, CV_64F);;
    NSMutableArray* matArray = (NSMutableArray*) [[NSUserDefaults standardUserDefaults] objectForKey:key];
    // NSLog(@"array values are %@", matArray); // debug
    for (int i=0 ; i< size.width * size.height; i++)
    {
        result.at<double>(i/size.width,i%size.width) = [(NSNumber*)[matArray objectAtIndex:i ] doubleValue];
        // NSLog(@"value of cv::Mat at location %d %d is : %f", i/size.width, i%size.width, result.at<double>(i/size.width,i%size.width)); // debug
    }
    
    return result;
}

@end
