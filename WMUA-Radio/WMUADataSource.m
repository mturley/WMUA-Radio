//
//  WMUADataSource.m
//  WMUA-Radio
//
//  Created by Mike Turley on 11/17/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUADataSource.h"
#import "XMLDictionary.h"

#define XML_LAST10_URL @"http://wmua.radioactivity.fm/feeds/last10.xml"
#define XML_SHOWS_URL @"http://wmua.radioactivity.fm/feeds/shows.xml"
#define XML_SHOWONAIR_URL @"http://wmua.radioactivity.fm/feeds/showonair.xml"

@implementation WMUADataSource

+ (void)getDictFromXmlUrl:(NSString *)filename
       withSuccessHandler:(void(^)(NSDictionary *))successHandler
         withErrorHandler:(void(^)(NSError *))errorHandler
{
    NSURL *url = [NSURL URLWithString:filename];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if(!error) {
                                   NSDictionary *dict = [NSDictionary dictionaryWithXMLData: data];
                                   void (^_successHandler)(NSDictionary *) = [successHandler copy];
                                   _successHandler(dict);
                               } else {
                                   void (^_errorHandler)(NSError *) = [errorHandler copy];
                                   _errorHandler(error);
                               }
                           }];
}

+ (void)getShowOnAir:(void(^)(NSDictionary *))successHandler
    withErrorHandler:(void(^)(NSError *))errorHandler
{
    [self getDictFromXmlUrl: XML_SHOWONAIR_URL
         withSuccessHandler: successHandler
           withErrorHandler: errorHandler];
}

+ (void)getLast10Plays:(void(^)(NSDictionary *))successHandler
      withErrorHandler:(void(^)(NSError *))errorHandler
{
    [self getDictFromXmlUrl: XML_LAST10_URL
         withSuccessHandler: successHandler
           withErrorHandler: errorHandler];
}


@end
