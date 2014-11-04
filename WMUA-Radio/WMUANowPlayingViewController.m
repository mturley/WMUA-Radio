//
//  WMUAFirstViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUANowPlayingViewController.h"
#import "XMLDictionary.h"

#define STREAM_URL @"http://ice7.securenetsystems.net/WMUA"

#define XML_LAST10_URL @"http://wmua.radioactivity.fm/feeds/last10.xml"
#define XML_SHOWS_URL @"http://wmua.radioactivity.fm/feeds/shows.xml"
#define XML_SHOWONAIR_URL @"http://wmua.radioactivity.fm/feeds/showonair.xml"

@interface WMUANowPlayingViewController ()

@end

@implementation WMUANowPlayingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    playing = NO;
    buffering = NO;
    
    // Tweaks to the UI that were unavailable in Interface Builder
    _playButton.layer.cornerRadius = 10;
    _playButton.layer.borderWidth = 0.5f;
    _playButton.layer.borderColor = [_playButton tintColor].CGColor;
    
    // Allocate, connect, and start the Radio streamer.
    radio = [[Radio alloc] init];
    [radio connect:STREAM_URL withDelegate:self withGain:(1.0)];
    [self startRadio];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.  
}

# pragma mark -
# pragma mark Playback Control Methods

- (void)startRadio {
    playing = YES;
    buffering = NO;
    [radio updatePlay:YES];
    [self updatePlayerUI];
}

- (void)stopRadio {
    playing = NO;
    buffering = NO;
    [radio updatePlay:NO];
    [self updatePlayerUI];
}

- (IBAction)toggleRadio:(id)sender {
    if (playing) {
        [self stopRadio];
    } else {
        [self startRadio];
    }
}

#pragma mark -
#pragma mark RadioDelegate Methods

- (void)updateBuffering:(BOOL)value {
    NSLog(@"delegate update buffering %d", value);
    if(value) {
        buffering = YES;
    } else {
        buffering = NO;
    }
    [self updatePlayerUI];
}

- (void)interruptRadio {
    NSLog(@"delegate radio interrupted");
    playing = NO;
    [self updatePlayerUI];
}

- (void)resumeInterruptedRadio {
    NSLog(@"delegate resume interrupted radio");
    playing = YES;
    [self updatePlayerUI];
}

- (void)networkChanged {
    NSLog(@"delegate network changed");
}

- (void)connectProblem {
    NSLog(@"delegate connection problem");
    playing = NO;
    buffering = NO;
    [self updatePlayerUI];
    [self alert:@"Connection Problem" withMessage:@"We can't seem to connect you to the WMUA audio stream. Please make sure your device is connected to the internet and try again."];
}

- (void)audioUnplugged {
    NSLog(@"delegate audio unplugged");
}

#pragma mark -
#pragma mark XML/RSS Methods
- (void)getDictFromXmlUrl:(NSString *)filename
       withSuccessHandler:(void(^)(NSDictionary *))successHandler
         withErrorHandler:(void(^)(NSError *))errorHandler {
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

- (IBAction)testXml:(id)sender{
    [self getDictFromXmlUrl:XML_LAST10_URL withSuccessHandler:^(NSDictionary *dict) {
        NSLog(@"PARSED DATA KEYS:");
        NSLog(@"%@", dict[@"channel"][@"item"]);
    } withErrorHandler:^(NSError *error) {
        NSLog(@"ERROR FETCHING XML FILE!");
    }];
}

#pragma mark -
#pragma mark UI Helper Methods
- (void)updatePlayerUI {
    if(playing) {
        // Begin a background task so that playback can continue when user leaves this view.
        bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
        if(buffering) {
            [_bufferingIndicator startAnimating];
            [_statusLabel setText:@"Buffering..."];
        } else {
            [_bufferingIndicator stopAnimating];
            [_statusLabel setText:@"Streaming Live"];
        }
        [_playButton setTitle:@"Stop" forState:UIControlStateNormal];
        UIImage *stopIcon = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:stopIcon forState:UIControlStateNormal];
    } else {
        [_bufferingIndicator stopAnimating];
        [_statusLabel setText:@"Stopped"];
        [_playButton setTitle:@"Listen Live" forState:UIControlStateNormal];
        UIImage *playIcon = [[UIImage imageNamed:@"play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:playIcon forState:UIControlStateNormal];
        // End the background task so the application can be removed from memory properly
        if (bgTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
        }
    }
}

- (void)alert:(NSString *)title withMessage:(NSString *)message
{
    // TODO deal with the UIAlertView deprecation in iOS 8?
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
