//
//  SummaryViewController.m
//  jiankongbao
//
//  Created by Tomasen on 2/20/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import "SummaryViewController.h"
#import "TMAppDelegate.h"

@interface SummaryViewController ()

@end

@implementation SummaryViewController

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
  
  // Do any additional setup after loading the view.
	[(TMAppDelegate*)[[UIApplication sharedApplication] delegate] setModalSummaryViewController:self];
  
  [self.redLabel setBackgroundColor:COLORPIERED];
  [self.redLabel setHidden:NO];
  [self.greenLabel setBackgroundColor:COLORPIEGREEN];
  [self.greenLabel setHidden:NO];
	
  [self.piechart setPieBackgroundColor:UIColorFromRGB(0x3498DB)];
  
  adsBannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
  adsBannerView_.adUnitID = @"a15307453637a13";
  adsBannerView_.rootViewController = self;
  [adsBannerView_ setHidden:YES];
  [self.view addSubview:adsBannerView_];
  
}

- (void)viewDidLayoutSubviews
{
  [self reArangeViews];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
	[(TMAppDelegate*)[[UIApplication sharedApplication] delegate] setModalSummaryViewController:nil];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidAppear:(BOOL)animated {
  
  self.screenName = @"项目总览";
  
  [self.piechart setDelegate:self];
  [self.piechart setDataSource:[TMJKB _instance]];
  [self.piechart setStartPieAngle:M_PI_2*4];
  [self.piechart setAnimationSpeed:2.0f];
  [self.piechart setLabelFont:[UIFont fontWithName:@"DBLCDTempBlack" size:24]];
  [self.piechart setShowPercentage:NO];
  [self.piechart setUserInteractionEnabled:YES];
  [self.piechart setLabelShadowColor:[UIColor blackColor]];
  
  [self.piechartLabel.layer setCornerRadius:[self piechartLabel].bounds.size.width/2];
  
  [self showPieChart];
  
}

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
  return 0;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
  return 0;
}

- (void) reArangeViews
{
  CGFloat adsHeight = 0;
  if (![adsBannerView_ isHidden])
  {
    CGRect adsFrame = adsBannerView_.frame;
    adsHeight = adsFrame.size.height;
    adsFrame.origin.y = self.view.frame.origin.x + self.view.frame.size.height - adsHeight;
    [adsBannerView_ setFrame:adsFrame];
  }
	
  CGRect buttonFrame = _logoutButton.frame;
  buttonFrame.origin.y = self.view.frame.origin.x + self.view.frame.size.height - adsHeight - buttonFrame.size.height;
  [_logoutButton setFrame:buttonFrame];
	
  CGRect noadsButtonFrame = _noadsButton.frame;
  noadsButtonFrame.origin.y = buttonFrame.origin.y;
  [_noadsButton setFrame:noadsButtonFrame];
	
  
	CGRect restoreButtonFrame = _restoreButton.frame;
  restoreButtonFrame.origin.y = buttonFrame.origin.y;
  [_restoreButton setFrame:restoreButtonFrame];
  
  if (![_tasksListView isHidden])
  {
    CGRect taskFrame = self.tasksListView.frame;
    taskFrame.size.height = _logoutButton.frame.origin.y - self.tasksListView.frame.origin.y - 8;
    [self.tasksListView setFrame:taskFrame];
  }
  
  constraintLogoutButton_.constant = adsHeight;
  constraintNoadsButton_.constant = adsHeight;
	constraintRestoreButton_.constant = adsHeight;
  
  [_noadsButton setHidden:[[TMJKB _instance] shouldShowPurchaseOption]];
  [_restoreButton setHidden:[[TMJKB _instance] shouldShowPurchaseOption]];
}

- (void) showPieChart
{
  [_refreshTimer invalidate];
  _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:180 target:self selector:@selector(refreshTaskList:) userInfo:nil repeats:NO];
  
  if ([TMJKB _instance].taskError <= 0) {
    [self.statusLabel setText:@"太好了！没有任何监控项目故障"];
    [self.tasksListView setHidden:YES];
    
  } else {
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"您有%ld个监控项目故障！", (long)[TMJKB _instance].taskError]];
    [text addAttribute: NSForegroundColorAttributeName value: [UIColor redColor] range: NSMakeRange(2, [NSString stringWithFormat:@"%ld", (long)[TMJKB _instance].taskError].length)];
    [self.statusLabel setAttributedText:text];
    
    NSMutableString* html = [NSMutableString stringWithString:@"<html><head><style>a {color: rgb(5, 142, 196);  font-family: Verdana;font-size: 12px;  line-height: 14px; text-decoration: none;}</style></head><body style='text-align:center'>"];
    for (NSString* key in [TMJKB _instance].faultyTasks) {
      NSString* name = [[[TMJKB _instance].faultyTasks objectForKey:key] objectForKey:@"task_name"];
      [html appendFormat:@" <a href=\"http://www.jiankongbao.com/task/%@\">%@</a> ", key, name];
    }
    [html appendString:@" </body></html"];
    [self.tasksListView setDelegate:self];
    [self.tasksListView loadHTMLString:html baseURL:nil];
    [self.tasksListView setHidden:NO];
    
  }
  
  [adsBannerView_ setHidden:[[TMJKB _instance] shouldShowAds]];
  [self reArangeViews];
  
  // show ads
  if (![adsBannerView_ isHidden]) {
    [adsBannerView_ loadRequest:[GADRequest request]];
  }
	
  [self.piechart reloadData];
}

- (IBAction)logOut:(id)sender {
  [[TMJKB _instance].keychain resetKeychainItem];
  [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
	
  [self dismissViewControllerAnimated:YES completion:nil];
	
}

- (IBAction)restorePurchase:(id)sender {
  [[TMJKB _instance] setPurchaseDelegate:self];
  [[TMJKB _instance] restorePreviousTransaction:self];
}

- (IBAction)noMoreAds:(id)sender {
  [[TMJKB _instance] setPurchaseDelegate:self];
  [[TMJKB _instance] restorePreviousTransaction:self];
}

- (void)purchaseFinished:(BOOL)noAds withMessage:(NSString *)msg
{
  if ([msg length] != 0)
  {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
  }
  
  if (noAds) {
    [adsBannerView_ setHidden:noAds];
    [_noadsButton setHidden:noAds];
		[_restoreButton setHidden:noAds];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"谢谢"
                                                    message:@"广告已去除"
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
  }
  [self reArangeViews];
}

- (IBAction)refreshTaskList:(id)sender {
  
  [self.tasksListView loadHTMLString:@"<html><body></body></html>" baseURL:nil];
  [self.tasksListView setHidden:YES];
  [self.statusLabel setText:@"读取中..."];
  [self.piechart setDataSource:self];
  [self.piechart reloadData];
  
  [[TMJKB _instance] fetchTaskList:nil completeHandler:^(NSInteger statusCode)
   {
     [self.piechart setDataSource:[TMJKB _instance]];
     [self.piechart reloadData];
     
     switch (statusCode) {
       case 200:
         [self showPieChart];
         break;
         
       default:
         [self.statusLabel setText:[NSString stringWithFormat:@"读取项目列表时发生了错误: %ld", (long)statusCode]];
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误"
                                                         message:@"读取项目列表时发生了错误"
                                                        delegate:nil
                                               cancelButtonTitle:@"确定"
                                               otherButtonTitles:nil];
         [alert show];
         break;
     }
     
	 }];
	
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  if (navigationType == UIWebViewNavigationTypeLinkClicked)
  {
    [[UIApplication sharedApplication] openURL:request.URL];
    return false;
  }
  
  return true;
}

@end
