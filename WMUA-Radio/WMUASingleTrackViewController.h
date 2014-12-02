//
//  WMUASingleTrackViewController.h
//  WMUA-Radio
//
//  Created by Mike Turley on 12/2/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMUASingleTrackViewController : UIViewController {
    NSDictionary *currentItunesUrls;
}

@property (strong, nonatomic) NSDictionary *trackDict;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIButton *iTunesButton;
@property (weak, nonatomic) IBOutlet UIImageView *coverArtView;

@end
