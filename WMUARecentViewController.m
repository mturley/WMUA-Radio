//
//  WMUARecentViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 11/18/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUARecentViewController.h"
#import "WMUATrackTableViewCell.h"
#import "WMUADataSource.h"

@interface WMUARecentViewController ()

@end

@implementation WMUARecentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Asychronously load "Recent Plays" data and display it.
    UINib *cellNib = [UINib nibWithNibName:@"WMUATrackTableViewCell" bundle:nil];
    [self.recentPlaysTable registerNib:cellNib forCellReuseIdentifier:@"TrackCell"];
    [self refreshRecentPlays];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)refreshButtonPressed:(id)sender {
    [self refreshRecentPlays];
}

- (void)refreshRecentPlays {
    recentPlays = [[NSArray alloc] init];
    [self.recentPlaysTable reloadData];
    [WMUADataSource getLast10Plays:^(NSDictionary *dict) {
        recentPlays = dict[@"channel"][@"item"];
        [self.recentPlaysTable reloadData];
    } withErrorHandler:^(NSError *error) {
        NSLog(@"ERROR FETCHING XML FILE!");
    }];
}


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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
