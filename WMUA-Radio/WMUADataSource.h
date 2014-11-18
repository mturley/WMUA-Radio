//
//  WMUADataSource.h
//  WMUA-Radio
//
//  Created by Mike Turley on 11/17/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMUADataSource : NSObject

+(void)getDictFromXmlUrl:(NSString *) filename
      withSuccessHandler:(void(^)(NSDictionary *))successHandler
        withErrorHandler:(void(^)(NSError *))errorHandler;

+ (void)getShowOnAir:(void(^)(NSDictionary *))successHandler
    withErrorHandler:(void(^)(NSError *))errorHandler;

+ (void)getLast10Plays:(void(^)(NSDictionary *))successHandler
    withErrorHandler:(void(^)(NSError *))errorHandler;

@end
