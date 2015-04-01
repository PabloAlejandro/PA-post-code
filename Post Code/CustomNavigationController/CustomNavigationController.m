//
//  NavigationControllerLogo.m
//  Air Comments
//
//  Created by Pablo Alejandro Perez Martinez on 13/01/14.
//  Copyright (c) 2014 Air Comments. All rights reserved.
//

#import "CustomNavigationController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup
{
    [self removeShadowOfBar];
    
    //[self.navigationBar setBarTintColor:[UIColor blackColor]];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationBar setTranslucent:YES];
    
    //[self showLogo];
}

- (void)showLogo
{
    /* Logo in the navigation bar */
    UIImage *imageLogo = [UIImage imageNamed:@"PC_bar_logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 15)];
    imageView.tag = -1;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [imageView setImage:imageLogo];
    [imageView setCenter:CGPointMake(self.navigationBar.center.x, 25)];
    [self.navigationBar addSubview:imageView];
    /* End logo */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)removeShadowOfBar
{
    // Remove the shadow line in the navigation bar
    UIView *view = [self.navigationBar.subviews objectAtIndex:0];
    for (UIView *view2 in view.subviews) {
        if ([view2 isKindOfClass:[UIImageView class]]) {
            [view2 removeFromSuperview];
        }
    }
}

@end
