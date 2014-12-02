//
//  WMUASingleTrackViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 12/2/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUASingleTrackViewController.h"
#import "WMUADataSource.h"
#import "UIImageView+WebCache.h"

@interface WMUASingleTrackViewController ()

@end

@implementation WMUASingleTrackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *track = _trackDict[@"ra:track"];
    NSString *album = _trackDict[@"ra:album"];
    NSString *artist = _trackDict[@"ra:artist"];
    
    [_trackLabel setText:track];
    [_albumLabel setText:album];
    [_artistLabel setText:artist];
    
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
                                  [self.view setNeedsDisplay];
                              }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    }
    [self.view setNeedsDisplay];
}

- (void)openItunesUrl:(NSString *)url {
    #if TARGET_IPHONE_SIMULATOR
        [self alert:@"No iTunes Store on Simulator" withMessage:@"The iTunes Store is not supported on the iOS Simulator. On a real device, the iTunes Store app would open instead of this message."];
    #else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    #endif
}

- (IBAction)iTunesButtonPressed:(id)sender {
    if(currentItunesUrls) {
        [self openItunesUrl:currentItunesUrls[@"trackViewUrl"]];
    } else {
        [self alert:@"Not Available on iTunes" withMessage:@"This song could not be found on the iTunes Music Store."];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
