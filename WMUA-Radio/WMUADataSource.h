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

+ (void)getArtworkUrlForAlbum:(NSString *)albumName
                     byArtist:(NSString *)artistName
                       inSize:(NSString *)size        // size must be @"60x60", @"100x100", @"200x200", @"400x400" or @"600x600"
                  withHandler:(void(^)(NSString *))handler;

@end
