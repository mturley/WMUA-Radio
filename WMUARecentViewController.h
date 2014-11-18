//
//  WMUARecentViewController.h
//  WMUA-Radio
//
//  Created by Mike Turley on 11/18/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMUARecentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSArray *recentPlays;
}

@property (weak, nonatomic) IBOutlet UITableView *recentPlaysTable;

@end
