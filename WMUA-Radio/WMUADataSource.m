//
//  WMUADataSource.m
//  WMUA-Radio
//
//  Created by Mike Turley on 11/17/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUADataSource.h"
#import "XMLDictionary.h"
#import "UNIRest.h"

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

+ (void)getArtworkUrlForAlbum:(NSString *)albumName
                     byArtist:(NSString *)artistName
                       inSize:(NSString *)size        // size must be @"60x60", @"100x100", @"200x200", @"400x400" or @"600x600"
                  withHandler:(void(^)(NSString *))handler
{
    NSString *urlRoot = @"https://itunes.apple.com/search?term=";
    NSString *termWithSpaces = [[artistName stringByAppendingString:@" "] stringByAppendingString:albumName];
    NSString *termWithPluses = [termWithSpaces stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *url = [[urlRoot stringByAppendingString:termWithPluses] stringByAppendingString:@"&entity=album"];
    
    NSDictionary *headers = @{@"accept": @"application/json"};
    
    [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:url];
        [request setHeaders:headers];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        void (^_handler)(NSString *) = [handler copy];
        if(!error) {
            NSDictionary *obj = response.body.object;
            if([obj[@"resultCount"] integerValue] > 0) {
                NSString *rawArtworkUrl = obj[@"results"][0][@"artworkUrl100"];
                NSString *sizedArtworkUrl = [rawArtworkUrl stringByReplacingOccurrencesOfString:@"100x100" withString:size];
                _handler(sizedArtworkUrl);
            } else {
                _handler(nil);
            }
        } else {
            _handler(nil);
        }
    }];
}


@end
