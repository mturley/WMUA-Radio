//
//  WMUAFirstViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUANowPlayingViewController.h"

#define STREAM_URL @"http://ice7.securenetsystems.net/WMUA"

@interface WMUANowPlayingViewController ()

@end

@implementation WMUANowPlayingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    playing = NO;
    buffering = NO;
    
    // Tweaks to the UI that were unavailable in Interface Builder
    _playButton.layer.cornerRadius = 10;
    _playButton.layer.borderWidth = 0.5f;
    _playButton.layer.borderColor = [_playButton tintColor].CGColor;
    
    // Allocate, connect, and start the Radio streamer class.
    radio = [[Radio alloc] init];
    [radio connect:STREAM_URL withDelegate:self withGain:(1.0)];
    [self startRadio];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.  
}

# pragma mark -
# pragma mark Playback Control Methods

- (void)startRadio
{
    // Start the background task so playback continues over lockscreen and other apps
    // TODO: replace with proper AudioSession?  See docs
    bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
    
    // Start the stream
    playing = YES;
    buffering = NO;
    [radio updatePlay:YES];
    
    // Update the view
    [self updatePlayerUI];
}

- (void)stopRadio
{
    // Stop the stream
    playing = NO;
    [radio updatePlay:NO];
    
    // Update the view
    [self updatePlayerUI];
    
    // End the background task so the application can be removed from memory properly
    if (bgTaskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
    }
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
}

- (void)resumeInterruptedRadio {
    NSLog(@"delegate resume interrupted radio");
}

- (void)networkChanged {
    NSLog(@"delegate network changed");
}

- (void)connectProblem {
    NSLog(@"delegate connection problem");
}

- (void)audioUnplugged {
    NSLog(@"delegate audio unplugged");
}

#pragma mark -
#pragma mark UI Helper Methods
- (void)updatePlayerUI {
    if(playing) {
        if(buffering) {
            [_statusLabel setText:@"Buffering..."];
        } else {
            [_statusLabel setText:@"Streaming Live"];
        }
        [_playButton setTitle:@"Stop" forState:UIControlStateNormal];
        UIImage *stopIcon = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:stopIcon forState:UIControlStateNormal];
    } else {
        [_statusLabel setText:@"Stopped"];
        [_playButton setTitle:@"Listen Live" forState:UIControlStateNormal];
        UIImage *playIcon = [[UIImage imageNamed:@"play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:playIcon forState:UIControlStateNormal];
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
