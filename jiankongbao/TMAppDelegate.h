//
//  TMAppDelegate.h
//  jiankongbao
//
//  Created by Tomasen on 2/19/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SummaryViewController.h"

@interface TMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SummaryViewController *modalSummaryViewController;

@end
