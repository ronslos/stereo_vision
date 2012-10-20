//
//  TimeDelayCalculation.h
//  stereo_vision
//
//  Created by Omer Shaked on 10/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef _time_delay_calculation_
#define _time_delay_calculation_

#import <Foundation/Foundation.h>

@interface TimeDelayCalculation : NSObject

+ (double) calculateInitialDelay: (NSMutableArray*) rtts;

+ (double) calculateUpdatedDelay: (NSMutableArray*) newrtts withPrevDelay: (double) delay;

@end

#endif