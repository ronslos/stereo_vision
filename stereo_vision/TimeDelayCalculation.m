//
//  TimeDelayCalculation.m
//  stereo_vision
//
//  Created by Omer Shaked on 10/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TimeDelayCalculation.h"

@implementation TimeDelayCalculation

+ (double) calculateInitialDelay: (NSMutableArray*) rtts
{
    double rtt_vals[10];
    double avg_delay = 0;
    double sum_delay = 0;
    int count = [rtts count];
    
    // get values into an array of doubles and calculate avg delay
    for (int i = 0 ; i < count; i++)
    {
        rtt_vals[i] = [(NSNumber*)[rtts objectAtIndex:i ] doubleValue];
        sum_delay += rtt_vals[i];
    } 
    
    // calculate average delay from all rtts
    avg_delay = sum_delay / count;
    
    int final_count = count;
    // remove calculations that are far from the avg
    for (int i = 0; i < count; i++) {
        double gap = abs(rtt_vals[i] - avg_delay);
        if (gap > 0.02){
            // ignore this rtt measurment
            sum_delay -= rtt_vals[i];
            final_count--;
        }
    }
    
    // calculate final delay from chosen rtts - divide by 2 for rtt / 2
    avg_delay = sum_delay / (final_count * 2);
    return avg_delay;
}

+ (double) calculateUpdatedDelay: (NSMutableArray*) newrtts withPrevDelay: (double) delay
{
    // calculate avg delay of newly received values
    double newDelay = [TimeDelayCalculation calculateInitialDelay:newrtts];
    
    // if significant gap from initial calculation, use the new value
    double diff = abs(delay - newDelay);
    if ((diff > 0.02) && (newDelay != 0)) {
        return newDelay;
    }
    else {
        return delay;
    }
}

@end
