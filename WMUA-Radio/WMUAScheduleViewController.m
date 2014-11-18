//
//  WMUAScheduleViewController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 10/26/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

#import "WMUAScheduleViewController.h"

#define SCHEDULE_PAGE_URL @"http://wmua.org/schedule.html"

@interface WMUAScheduleViewController ()

@end

@implementation WMUAScheduleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)configureView {
    NSURL *url = [NSURL URLWithString:SCHEDULE_PAGE_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (IBAction)reloadSchedule:(id)sender {
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark -
# pragma mark UIWebViewDelegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loadingIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView
didFailLoadWithError:(NSError *)error {
    [self.loadingIndicator stopAnimating];
    // TODO refactor/combine with other alert method from NowPlaying and replace for iOS 8?
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Problem"
                                                    message:@"Failed to load the WMUA schedule webpage. Please make sure your device is connected to the internet and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
