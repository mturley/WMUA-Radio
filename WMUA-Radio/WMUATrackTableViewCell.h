//
//  WMUATrackTableViewCell.h
//  WMUA-Radio
//
//  Created by Mike Turley on 11/4/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMUATrackTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *playNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *genreLabel;

@end
