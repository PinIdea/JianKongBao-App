//
//  TMViewController.h
//  jiankongbao
//
//  Created by Tomasen on 2/19/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAI.h"

@interface TMViewController : GAITrackedViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *accountTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet UILabel *messageBox;

- (IBAction)logOn:(id)sender;
@end
