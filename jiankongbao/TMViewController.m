//
//  TMViewController.m
//  jiankongbao
//
//  Created by Tomasen on 2/19/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import "TMViewController.h"
#import "TMJKB.h"

@interface TMViewController ()

@end

@implementation TMViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  NSString* authstr = [[TMJKB _instance] getAuthStr];
  
  if ([authstr length] != 0 && [authstr isKindOfClass:[NSString class]]){
    NSArray *auth_params = [authstr componentsSeparatedByString:@":"];
    if ([auth_params count] >= 1) {
      _accountTextField.text = [auth_params objectAtIndex:0];
    }
    if ([auth_params count] >= 2) {
      _passwordTextField.text = [auth_params objectAtIndex:1];
      [self jkbTryLogin:authstr];
    }
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
  
  self.screenName = @"登录";
  
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == _accountTextField) {
    [textField resignFirstResponder];
    [_passwordTextField becomeFirstResponder];
  } else if (textField == _passwordTextField) {
    [textField resignFirstResponder];
    [self logOn:self];
  }
  return YES;
}

- (IBAction)logOn:(id)sender {
  if ([_accountTextField.text length] == 0) {
    [_accountTextField becomeFirstResponder];
    return;
  }
  
  if ([_passwordTextField.text length] == 0) {
    [_passwordTextField becomeFirstResponder];
    return;
  }
  
  [self jkbTryLogin:[NSString stringWithFormat:@"%@:%@", _accountTextField.text, _passwordTextField.text]];
}

- (void)disablePanel:(BOOL)disabled {
  [self.view endEditing:YES];
  [_accountTextField setEnabled:!disabled];
  [_passwordTextField setEnabled:!disabled];
  [_submitButton setEnabled:!disabled];
  
}

- (void)jkbTryLogin:(NSString*)authStr {
  
  [self disablePanel:YES];
  [_indicatorView startAnimating];
  
  [[TMJKB _instance] fetchTaskList:authStr completeHandler:^(NSInteger statusCode)
   {
     [_indicatorView stopAnimating];
     [self disablePanel:NO];
		 
     switch (statusCode) {
       case 200:
         [_messageBox setHidden:YES];
         [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
         [self performSegueWithIdentifier:@"showStatusView" sender:self];
         break;
         
       case 401:
         // failed
         [_messageBox setText:@"无效的账号或密码"];
         [_messageBox setHidden:NO];
         [_accountTextField becomeFirstResponder];
         break;
         
       default:
         [_messageBox setText:[NSString stringWithFormat:@"未知错误 %ld", (long)statusCode]];
         [_messageBox setHidden:NO];
         [_accountTextField becomeFirstResponder];
         break;
     }
     
   }];
}
@end
