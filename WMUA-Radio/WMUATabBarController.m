//
//  WMUATabBarController.m
//  WMUA-Radio
//
//  Created by Mike Turley on 11/18/14.
//  Copyright (c) 2014 Mike Turley. All rights reserved.
//

// This file is shamelessly borrowed from http://travisjbeck.com/blog/ios/uitabbarcontroller-with-push-transition/

#import "WMUATabBarController.h"

@interface WMUATabBarController ()

@property (nonatomic) BOOL isAnimating;

@end

@implementation WMUATabBarController

@synthesize isAnimating;

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    int controllerIndex = [[tabBarController viewControllers] indexOfObject:viewController];
    
    if(controllerIndex == self.selectedIndex || self.isAnimating){
        return NO;
    }
    
    // Get the views.
    UIView * fromView = tabBarController.selectedViewController.view;
    UIView * toView = [viewController view];
    
    // Get the size of the view area.
    CGRect viewSize = fromView.frame;
    BOOL scrollRight = controllerIndex > tabBarController.selectedIndex;
    
    // Add the to view to the tab bar view.
    [fromView.superview addSubview:toView];
    
    // Position it off screen.
    toView.frame = CGRectMake((scrollRight ? 320 : -320), viewSize.origin.y, 320, viewSize.size.height);
    
    [UIView animateWithDuration:0.3
                     animations: ^{
                         
                         // Animate the views on and off the screen. This will appear to slide.
                         fromView.frame =CGRectMake((scrollRight ? -320 : 320), viewSize.origin.y, 320, viewSize.size.height);
                         toView.frame =CGRectMake(0, viewSize.origin.y, 320, viewSize.size.height);
                     }
     
                     completion:^(BOOL finished) {
                         if (finished) {
                             // Remove the old view from the tabbar view.
                             [fromView removeFromSuperview];
                             tabBarController.selectedIndex = controllerIndex;
                         }
                     }];
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end