//
//  WMUAFirstViewController.h
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Radio.h"

@interface WMUANowPlayingViewController : UIViewController <RadioDelegate, UITableViewDataSource, UITableViewDelegate> {
    Radio *radio;
    BOOL playing;
    BOOL buffering;
    UIBackgroundTaskIdentifier bgTaskID;
    NSArray *recentPlays;
}

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *bufferingIndicator;
@property (weak, nonatomic) IBOutlet UILabel *airingShowLabel;
@property (weak, nonatomic) IBOutlet UILabel *airingDJLabel;
@property (weak, nonatomic) IBOutlet UILabel *airingScheduleLabel;
@property (weak, nonatomic) IBOutlet UITableView *recentPlaysTable;
    
@end
