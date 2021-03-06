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
    _lateWarningLabel.layer.cornerRadius = 10;
    _lateWarningLabel.layer.masksToBounds = YES;
    _lateWarningLabel.layer.shouldRasterize = YES;
    
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
    
    // Send album art to back
    coverArtInForeground = NO;
    [[_coverArtView superview] sendSubviewToBack:_coverArtView];
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
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                    target:self
                                                  selector:@selector(refreshTimerTick:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)refreshTimerTick:(NSTimer *)timer {
    if(playing) {
        [self refreshNowAiring];
    } else {
        [timer invalidate];
        refreshTimer = nil;
    }
}

- (void)stopRadio {
    playing = NO;
    buffering = NO;
    [radio updatePlay:NO];
    [self updatePlayerUI];
    [refreshTimer invalidate];
    refreshTimer = nil;
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
    [self addFadeAnimationTo:_playButton];
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
    [_bufferingIndicator startAnimating];
    [WMUADataSource getShowOnAir:^(NSDictionary *dict) {
        NSDictionary *showDict = dict[@"channel"][@"item"];
        [self addFadeAnimationTo:_airingShowLabel];
        [self addFadeAnimationTo:_airingDJLabel];
        [self addFadeAnimationTo:_airingScheduleLabel];
        if(showDict[@"ra:showname"]) {
            [_airingShowLabel setText:showDict[@"ra:showname"]];
            if([showDict[@"ra:showdj"] isKindOfClass:[NSArray class]]) {
                [_airingDJLabel setText:[showDict[@"ra:showdj"] componentsJoinedByString:@", "]];
            } else {
                [_airingDJLabel setText:showDict[@"ra:showdj"]];
            }
            [_airingScheduleLabel setText:showDict[@"ra:showschedule"]];
        } else {
            [_airingShowLabel setText:@"(No Data Available)"];
            [_airingDJLabel setText:@""];
            [_airingScheduleLabel setText:@""];
        }
        if(!buffering) {
            [_bufferingIndicator stopAnimating];
        }
        if(showDict[@"ra:latewarning"] && ![showDict[@"ra:latewarning"] isEqualToString:@""]) {
            [self addFadeAnimationTo:_lateWarningLabel];
            [_lateWarningLabel setHidden: NO];
        } else {
            [self addFadeAnimationTo:_lateWarningLabel];
            [_lateWarningLabel setHidden: YES];
        }
    } withErrorHandler:^(NSError *error) {
        [self addFadeAnimationTo:_airingShowLabel];
        [self addFadeAnimationTo:_airingDJLabel];
        [self addFadeAnimationTo:_airingScheduleLabel];
        [_airingShowLabel setText:@"(No Data Available)"];
        [_airingDJLabel setText:@""];
        [_airingScheduleLabel setText:@""];
        [self setAlbumArt:nil];
        if(!buffering) {
            [_bufferingIndicator stopAnimating];
        }
    }];
    
    // Display latest track album art and labels
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
        [_iTunesStoreButton setEnabled:YES];
        [_iTunesStoreButton setNeedsDisplay];
        [_currentTrackView setNeedsDisplay];
        [self.view setNeedsDisplay];
        if(![album isEqualToString: currentAlbum] || ![artist isEqualToString: currentArtist]) {
            currentAlbum = album;
            currentArtist = artist;
            currentItunesUrls = nil;
            [WMUADataSource getItunesUrlsForTrack:track
                                          onAlbum:album
                                         byArtist:artist
                                      withArtSize:@"400x400"
                                      withHandler:^(NSDictionary *result) {
                if(result) {
                    currentItunesUrls = result;
                    [self setAlbumArt:result[@"artworkUrl"]];
                } else {
                    [self setAlbumArt:nil];
                }
                [_iTunesStoreButton setNeedsDisplay];
                [_currentTrackView setNeedsDisplay];
                [self.view setNeedsDisplay];
            }];
        }
        if(!buffering) {
            [_bufferingIndicator stopAnimating];
        }
    } withErrorHandler:^(NSError *error) {
        currentArtist = nil;
        currentAlbum = nil;
        currentTrack = nil;
        [_iTunesStoreButton setEnabled:NO];
        [self setAlbumArt:nil];
        [self addFadeAnimationTo:_currentTrackNameLabel];
        [self addFadeAnimationTo:_currentTrackArtistLabel];
        [_currentTrackArtistLabel setText:@"(No Data Available)"];
        [_currentTrackNameLabel setText:@""];
        [_iTunesStoreButton setNeedsDisplay];
        [_currentTrackView setNeedsDisplay];
        [self.view setNeedsDisplay];
        if(!buffering) {
            [_bufferingIndicator stopAnimating];
        }
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

- (void)sendAlbumArtToBack {
    [[_coverArtView superview] sendSubviewToBack:_coverArtView];
    coverArtInForeground = NO;
}

- (void)bringAlbumArtToFront {
    [[_coverArtView superview] bringSubviewToFront:_coverArtView];
    coverArtInForeground = YES;
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(sendAlbumArtToBack)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)albumArtTapped:(UITapGestureRecognizer *)sender {
    if(coverArtInForeground) {
        [self sendAlbumArtToBack];
    } else {
        [self bringAlbumArtToFront];
    }
}

- (IBAction)viewOnItunesStore:(id)sender {
    if(currentItunesUrls) {
        if(!currentTrack) currentTrack = @"";
        if(!currentAlbum) currentAlbum = @"";
        if(!currentArtist) currentArtist = @"";
        NSString *trackButtonStr = [@"Track: " stringByAppendingString:currentTrack];
        NSString *albumButtonStr = [@"Album: " stringByAppendingString:currentAlbum];
        NSString *artistButtonStr = [@"Artist: " stringByAppendingString:currentArtist];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:trackButtonStr, albumButtonStr, artistButtonStr, nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    } else {
        [self alert:@"Not Available on iTunes" withMessage:@"This song could not be found on the iTunes Music Store."];
    }
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
    [self alert:@"No iTunes Store on Simulator" withMessage:@"The iTunes Store is not supported on the iOS Simulator. On a real device, the iTunes Store app would open instead of this message."];
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
