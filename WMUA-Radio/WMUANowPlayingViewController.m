//
//  WMUANowPlayingViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUANowPlayingViewController.h"
#import "WMUADataSource.h"

#define STREAM_URL @"http://ice7.securenetsystems.net/WMUA"

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
    
    // Asynchronously load "Now Airing" data and display it.
    [self refreshNowAiring];
    
    // Register for notifications of audio session interruption.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterruptionHappened:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    // Register to recieve Remote Control Events.
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
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

- (void)audioSessionInterruptionHappened:(NSNotification *)notification {
    [self stopRadio];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (playing) {
                    [self stopRadio];
                } else {
                    [self startRadio];
                }
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [self startRadio];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [self stopRadio];
                break;
                
            default:
                break;
        }
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
#pragma mark UI Helper Methods

- (void)updatePlayerUI {
    if(playing) {
        // Begin a background task so that playback can continue when user leaves this view.
        bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
        if(buffering) {
            [_bufferingIndicator startAnimating];
            [_playButton setTitle:@"Buffering... (Tap to Stop)" forState:UIControlStateNormal];
        } else {
            [_bufferingIndicator stopAnimating];
            [_playButton setTitle:@"Stop Live Streaming" forState:UIControlStateNormal];
        }
        UIImage *stopIcon = [[UIImage imageNamed:@"stop"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:stopIcon forState:UIControlStateNormal];
        [self refreshNowAiring];
        // TODO refresh recent plays in the other view??
    } else {
        [_bufferingIndicator stopAnimating];
        [_playButton setTitle:@"Listen Live Now" forState:UIControlStateNormal];
        UIImage *playIcon = [[UIImage imageNamed:@"play"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_playButton setImage:playIcon forState:UIControlStateNormal];
        // End the background task so the application can be removed from memory properly
        if (bgTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
        }
    }
}

- (IBAction)refreshButtonPressed:(id)sender {
    [self refreshNowAiring];
    // TODO refresh current track + album art
}

- (void)refreshNowAiring {
    [_airingShowLabel setText:@"Loading..."];
    [_airingDJLabel setText:@"Loading..."];
    [_airingScheduleLabel setText:@"Loading..."];
    [WMUADataSource getShowOnAir:^(NSDictionary *dict) {
        NSDictionary *showDict = dict[@"channel"][@"item"];
        [_airingShowLabel setText:showDict[@"ra:showname"]];
        [_airingDJLabel setText:[showDict[@"ra:showdj"] componentsJoinedByString:@", "]];
        [_airingScheduleLabel setText:showDict[@"ra:showschedule"]];
    } withErrorHandler:^(NSError *error) {
        [_airingShowLabel setText:@"(No Data Available)"];
        [_airingDJLabel setText:@"(No Data Available)"];
        [_airingScheduleLabel setText:@"(No Data Available)"];
    }];
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
