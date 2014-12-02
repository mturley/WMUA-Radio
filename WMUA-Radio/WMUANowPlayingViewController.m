//
//  WMUANowPlayingViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUANowPlayingViewController.h"
#import "WMUADataSource.h"
#import "UIImageView+WebCache.h"

#define STREAM_URL @"http://ice7.securenetsystems.net/WMUA"

@interface WMUANowPlayingViewController ()

@end

@implementation WMUANowPlayingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    playing = NO;
    buffering = NO;
    
    currentArtist = nil;
    currentAlbum = nil;
    currentTrack = nil;
    
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
    // Display current show on air
    [WMUADataSource getShowOnAir:^(NSDictionary *dict) {
        NSDictionary *showDict = dict[@"channel"][@"item"];
        [self addFadeAnimationTo:_airingShowLabel];
        [self addFadeAnimationTo:_airingDJLabel];
        [self addFadeAnimationTo:_airingScheduleLabel];
        [_airingShowLabel setText:showDict[@"ra:showname"]];
        if([showDict[@"ra:showdj"] isKindOfClass:[NSArray class]]) {
            [_airingDJLabel setText:[showDict[@"ra:showdj"] componentsJoinedByString:@", "]];
        } else {
            [_airingDJLabel setText:showDict[@"ra:showdj"]];
        }
        [_airingScheduleLabel setText:showDict[@"ra:showschedule"]];
    } withErrorHandler:^(NSError *error) {
        [self addFadeAnimationTo:_airingShowLabel];
        [self addFadeAnimationTo:_airingDJLabel];
        [self addFadeAnimationTo:_airingScheduleLabel];
        [_airingShowLabel setText:@"(No Data Available)"];
        [_airingDJLabel setText:@""];
        [_airingScheduleLabel setText:@""];
        [self setAlbumArt:nil];
    }];
    
    // Display latest track album art
    [WMUADataSource getLast10Plays:^(NSDictionary *dict) {
        NSDictionary *latestTrack = dict[@"channel"][@"item"][0];
        NSString *album = latestTrack[@"ra:album"];
        NSString *artist = latestTrack[@"ra:artist"];
        NSString *track = latestTrack[@"ra:track"];
        currentTrack = track;
        [self addFadeAnimationTo:_currentTrackNameLabel];
        [self addFadeAnimationTo:_currentTrackArtistLabel];
        [_currentTrackNameLabel setText:track];
        [_currentTrackArtistLabel setText:artist];
        if(![album isEqualToString: currentAlbum] || ![artist isEqualToString: currentArtist]) {
            currentAlbum = album;
            currentArtist = artist;
            [WMUADataSource getItunesUrlsForTrack:track
                                          onAlbum:album
                                         byArtist:artist
                                      withArtSize:@"400x400"
                                      withHandler:^(NSDictionary *result) {
                if(result) {
                    currentItunesUrls = result;
                    [_iTunesStoreButton setEnabled:YES];
                    [self setAlbumArt:result[@"artworkUrl"]];
                } else {
                    [_iTunesStoreButton setEnabled:NO];
                    [self setAlbumArt:nil];
                }
            }];
        }
    } withErrorHandler:^(NSError *error) {
        [self setAlbumArt:nil];
        [self addFadeAnimationTo:_currentTrackNameLabel];
        [self addFadeAnimationTo:_currentTrackArtistLabel];
        [_currentTrackArtistLabel setText:@"(No Data Available)"];
        [_currentTrackNameLabel setText:@""];
    }];
}

- (void)setAlbumArt:(NSString *)url {
    if(url) {
        [_coverArtView sd_setImageWithURL:[NSURL URLWithString:url]
                         placeholderImage:[UIImage imageNamed:@"wmua-320.png"]
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
            [_coverArtView setAlpha:0.0f];
            [UIView animateWithDuration:0.3 animations:^{
                [_coverArtView setAlpha:1.0f];
            }];
        }];
    } else {
        [_coverArtView setImage:[UIImage imageNamed: @"wmua-320.png"]];
        [_coverArtView setAlpha:0.5f];
    }
    [self.view setNeedsDisplay];
}

- (IBAction)viewOnItunesStore:(id)sender {
    NSString *trackButtonStr = [@"Track: " stringByAppendingString:currentTrack];
    NSString *albumButtonStr = [@"Album: " stringByAppendingString:currentAlbum];
    NSString *artistButtonStr = [@"Artist: " stringByAppendingString:currentArtist];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:trackButtonStr, albumButtonStr, artistButtonStr, nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0) { // Track
        [self openItunesUrl:currentItunesUrls[@"trackViewUrl"]];
    } else if(buttonIndex == 1) { // Album
        [self openItunesUrl:currentItunesUrls[@"albumViewUrl"]];
    } else if(buttonIndex == 2) { // Artist
        [self openItunesUrl:currentItunesUrls[@"artistViewUrl"]];
    }
}

- (void)openItunesUrl:(NSString *)url {
    #if TARGET_IPHONE_SIMULATOR
    NSLog(@"WMUA NOTE: iTunes Store is not supported on the iOS simulator. Unable to open Store page.");
    #else
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    #endif
}

- (void)addFadeAnimationTo:(UIView *)view {
    CATransition *transitionAnimation = [CATransition animation];
    [transitionAnimation setType:kCATransitionFade];
    [transitionAnimation setDuration:0.3f];
    [transitionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [transitionAnimation setFillMode:kCAFillModeBoth];
    [view.layer addAnimation:transitionAnimation forKey:@"fadeAnimation"];
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
