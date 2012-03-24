//
//  FacebookDataHandler.h
//  MappMe
//
//  Created by Parker Spielman on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*Class handles communication with Facebook Server for Data and Processes Returned Info*/
@interface FacebookDataHandler : NSObject

-(void)getCurrentLocation;
-(void)getHometownLocation;
-(void)getEducationInfo;
@end