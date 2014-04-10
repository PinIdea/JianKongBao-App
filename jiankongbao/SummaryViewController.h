//
//  SummaryViewController.h
//  jiankongbao
//
//  Created by Tomasen on 2/20/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"
#import "GAI.h"
#import "TMJKB.h"
#import "GADBannerView.h"

@interface SummaryViewController : GAITrackedViewController <TMJKBPurchaseDelegate, XYPieChartDelegate, UIWebViewDelegate, XYPieChartDataSource>
{
  GADBannerView *adsBannerView_;
  __weak IBOutlet NSLayoutConstraint *constraintLogoutButton_;
  __weak IBOutlet NSLayoutConstraint *constraintNoadsButton_;
	__weak IBOutlet NSLayoutConstraint *constraintRestoreButton_;
}

- (IBAction)refreshTaskList:(id)sender;

@property (weak, nonatomic) IBOutlet XYPieChart *piechart;
@property (weak, nonatomic) IBOutlet UILabel *piechartLabel;
@property (weak, nonatomic) IBOutlet UIView *redLabel;
@property (weak, nonatomic) IBOutlet UIView *greenLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIWebView *tasksListView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *noadsButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, readonly)  NSTimer* refreshTimer;
@end
