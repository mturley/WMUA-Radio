//
//  WMUAFirstViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUANowPlayingViewController.h"
#import "WMUATrackTableViewCell.h"
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
    
    // Asynchronously load "Now Airing" data and display it.
    [self refreshNowAiring];
    
    // Asychronously load "Recent Plays" data and display it.
    UINib *cellNib = [UINib nibWithNibName:@"WMUATrackTableViewCell" bundle:nil];
    [self.recentPlaysTable registerNib:cellNib forCellReuseIdentifier:@"TrackCell"];
    [self refreshRecentPlays];
    
    // Register for notifications of audio session interruption.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterruptionHappened:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
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
        [self refreshNowAiring];
        [self refreshRecentPlays];
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

- (IBAction)refreshNowAiring:(id)sender {
    [self refreshNowAiring];
}

- (void)refreshNowAiring {
    [_airingShowLabel setText:@"Loading..."];
    [_airingDJLabel setText:@"Loading..."];
    [_airingScheduleLabel setText:@"Loading..."];
    [self getDictFromXmlUrl:XML_SHOWONAIR_URL withSuccessHandler:^(NSDictionary *dict) {
        NSDictionary *showDict = dict[@"channel"][@"item"];
        [_airingShowLabel setText:showDict[@"ra:showname"]];
        [_airingDJLabel setText:[showDict[@"ra:showdj"] componentsJoinedByString:@", "]];
        [_airingScheduleLabel setText:showDict[@"ra:showschedule"]];
    } withErrorHandler:^(NSError *error) {
        NSLog(@"ERROR FETCHING XML FILE!");
        [_airingShowLabel setText:@"(No Data Available)"];
        [_airingDJLabel setText:@"(No Data Available)"];
        [_airingScheduleLabel setText:@"(No Data Available)"];
    }];
}

- (IBAction)refreshRecentPlays:(id)sender {
    [self refreshRecentPlays];
}

- (void)refreshRecentPlays {
    recentPlays = [[NSArray alloc] init];
    [self.recentPlaysTable reloadData];
    [self getDictFromXmlUrl:XML_LAST10_URL withSuccessHandler:^(NSDictionary *dict) {
        recentPlays = dict[@"channel"][@"item"];
        [self.recentPlaysTable reloadData];
    } withErrorHandler:^(NSError *error) {
        NSLog(@"ERROR FETCHING XML FILE!");
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

# pragma mark -
# pragma mark Recent Plays Table View Methods

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMUATrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TrackCell"];
    // Initialize the cell if it has not yet been created
    if(!cell) {
        cell = [[WMUATrackTableViewCell alloc] init];
    }
    NSDictionary *trackDict = [recentPlays objectAtIndex:indexPath.row];
    [cell.playNumLabel setText:trackDict[@"title"]];
    [cell.timeLabel setText:trackDict[@"ra:time"]];
    [cell.trackLabel setText:trackDict[@"ra:track"]];
    [cell.artistLabel setText:trackDict[@"ra:artist"]];
    [cell.albumLabel setText:trackDict[@"ra:album"]];
    [cell.genreLabel setText:trackDict[@"ra:genre"]];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [recentPlays count];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

@end
