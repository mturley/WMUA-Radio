//
//  WMUAAboutViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 11/18/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUAAboutViewController.h"

@interface WMUAAboutViewController ()

@end

@implementation WMUAAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)wwwHome:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://wmua.org/"]];
}

- (IBAction)wwwSports:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://wmuasportsamherst.wordpress.com/"]];
}

- (IBAction)wwwNews:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://wmuanews.wordpress.com/"]];
}

- (IBAction)wwwPodcasts:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://wmua.org/podcastgen2/"]];
}

- (IBAction)wwwMikeTurleyDotCom:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://miketurley.com/"]];
}

- (IBAction)wwwGithubMturley:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mturley"]];
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
