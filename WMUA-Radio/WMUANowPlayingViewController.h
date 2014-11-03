//
//  WMUAFirstViewController.h
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Radio.h"

@interface WMUANowPlayingViewController : UIViewController <RadioDelegate> {
    Radio *radio;
    BOOL playing;
    BOOL buffering;
    UIBackgroundTaskIdentifier bgTaskID;
}

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
    
@end
