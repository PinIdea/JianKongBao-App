//
//  TMJKB.m
//  jiankongbao
//
//  Created by Tomasen on 2/20/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import "TMJKB.h"
#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>

#define KEYCHAIN_KEY_AUTHSTR (__bridge id)kSecValueData

static TMJKB *_sharedTMJKBManager = nil;

@implementation TMJKB

+(TMJKB *)_instance
{
	if (!_sharedTMJKBManager)
    _sharedTMJKBManager = [[TMJKB alloc] init];
  
	return _sharedTMJKBManager;
}


- (id)init
{
	if ( self = [super init] ) {
		
		_flag = 0;
		
		Boolean result = FALSE;
		NSArray *addresses;
		CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)@"jkb.v.pinidea.co");
		if (hostRef != NULL) {
			result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // pass an error instead of NULL here to find out why it failed
			if (result == TRUE) {
				addresses = (NSArray*)CFBridgingRelease(CFHostGetAddressing(hostRef, &result));
			}
		}
		
		if (result == TRUE) {
			for(int i = 0; i < CFArrayGetCount(CFBridgingRetain(addresses)); i++){
				struct sockaddr_in* remoteAddr;
				CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(CFBridgingRetain(addresses), i);
				remoteAddr = (struct sockaddr_in*)CFDataGetBytePtr(saData);
				
				if(remoteAddr != NULL){
					// Extract the ip address
					_flag = (UInt32)remoteAddr->sin_addr.s_addr;
				}
			}
		}
		
    _keychain = [[KeychainItem alloc] initWithIdentifier:@"Auth_Info" accessGroup:nil];
    _faultyTasks = [NSMutableDictionary dictionary];
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    _noAds = [ud boolForKey:@"NOADS"];
    
    NSDate* installedData = [ud objectForKey:@"INSTALLDATE"];
    if (installedData == nil)
    {
      _noAds = YES;
      [ud setObject:[NSDate date] forKey:@"INSTALLDATE"];
      [ud synchronize];
    }
    else if ([installedData compare:[NSDate dateWithTimeIntervalSinceNow:-3600*24*4]] == NSOrderedDescending)
    {
      _noAds = YES;
    }
		
    if (_noAds)
    {
      [self registerDevice];
    }
		
    return self;
  }
  
	return nil;
}

-(BOOL) shouldShowAds
{
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	int n = (screenBounds.size.height>500)?8:0;
	
	return ((_taskError > n) || _noAds);
}

-(BOOL) shouldShowPurchaseOption
{
	return [TMJKB _instance].noAds || !([TMJKB _instance].flag&NOPURCHARSEOPTION);
}

- (void)setNoAds:(BOOL)noAds
{
  _noAds = noAds;
  [[NSUserDefaults standardUserDefaults] setBool:noAds forKey:@"NOADS"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  if (_purchaseDelegate != nil && [_purchaseDelegate respondsToSelector:@selector(purchaseFinished:withMessage:)])
  {
    [_purchaseDelegate purchaseFinished:noAds withMessage:nil];
  }
  
  if (_noAds)
  {
    [self registerDevice];
  }
}

- (void)restorePreviousTransaction:(id)sender
{
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)purchaseNoAds:(id)sender
{
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"no_ads_01"]];
	productsRequest.delegate = self;
	[productsRequest start];
}

-(NSString*) getAuthStr
{
#ifdef PASSWORD_USES_DATA
  
  NSLog(@"%@", [[TMJKB _instance].keychain objectForKey:KEYCHAIN_KEY_AUTHSTR]);
  return [[NSString alloc] initWithData:[[TMJKB _instance].keychain objectForKey:KEYCHAIN_KEY_AUTHSTR] encoding:NSUTF8StringEncoding];
#else
  return [[TMJKB _instance].keychain objectForKey:KEYCHAIN_KEY_AUTHSTR];
#endif
}

- (void)registerDevice
{
  NSLog(@"registerForRemoteNotificationTypes");
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
  if (queue.transactions.count > 0)
  {
    [self setNoAds:YES];
  }
  
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
  for (SKPaymentTransaction *transaction in transactions)
  {
    switch (transaction.transactionState) {
      case SKPaymentTransactionStatePurchased:
      case SKPaymentTransactionStateRestored:
        [self setNoAds:YES];
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        break;
      case SKPaymentTransactionStateFailed:
        
        if ([_purchaseDelegate respondsToSelector:@selector(purchaseFinished:withMessage:)])
        {
          [_purchaseDelegate purchaseFinished:NO withMessage:@"购买失败"];
        }
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        break;
    }
    
  }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
  SKProduct *validProduct = nil;
  int count = [response.products count];
  if(count > 0){
    validProduct = [response.products objectAtIndex:0];
    SKPayment *payment = [SKPayment paymentWithProduct:validProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
  }
  else if(!validProduct){
    // this is called if your product id is not valid, this shouldn't be called unless that happens.
    // [self setNoAds:YES];
  }
}

-(void) fetchTaskList:(NSString*)authStr completeHandler:(void (^)(NSInteger statusCode))handler
{
  if (authStr == nil)
  {
    authStr = lastAuthStr_;
  }
  
  if (authStr == nil)
  {
    handler(-1);
  }
  
  NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.jiankongbao.com/site/task/list.json"]
                                                            cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                        timeoutInterval:30];
  
  NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
  NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength|NSDataBase64EncodingEndLineWithCarriageReturn]];
  [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
  
  [NSURLConnection sendAsynchronousRequest:urlRequest
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse *response,
                                             NSData *data,
                                             NSError *error)
   {
     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
     
     if ([data length] > 0 && error == nil && [httpResponse statusCode] == 200 && [[TMJKB _instance] procJSON:data kind:@"list"])
     {
       // successsed
#ifdef PASSWORD_USES_DATA
       [[TMJKB _instance].keychain setObject:[authStr dataUsingEncoding:NSUTF8StringEncoding] forKey:KEYCHAIN_KEY_AUTHSTR];
#else
       [[TMJKB _instance].keychain setObject:authStr forKey:KEYCHAIN_KEY_AUTHSTR];
#endif
       
       lastAuthStr_ = authStr;
       [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_taskError];
			 
     }
		 
     handler([httpResponse statusCode]);
   }];
}

-(BOOL) procJSON:(NSData*)data kind:(NSString*)task
{
  NSError* error;
  NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
  if (error != nil) {
    return NO;
  }
  
  if ([task isEqualToString:@"list"]) {
    taskList_ = [dictionary objectForKey:@"tasks"];
    _taskTotal = 0;
    _taskError = 0;
    
    NSArray *tasks = [taskList_ objectForKey:@"task"];
    if ([taskList_ count] == 0 || [tasks count] == 0) {
      return YES;
    }
    
    [_faultyTasks removeAllObjects];
    
    NSDate* yestoday = [NSDate dateWithTimeIntervalSinceNow:-3600*24];
    
    for (NSDictionary *task in tasks){
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
      NSDate *lastCheckDate = [dateFormat dateFromString:[task objectForKey:@"last_check_time"]];
      
      if ([yestoday compare:lastCheckDate] == NSOrderedDescending)
      {
        continue;
      }
      
      if (![[task objectForKey:@"last_resp_result"] isEqualToString:@"1"]) {
        _taskError++;
        [_faultyTasks setObject:[NSDictionary dictionaryWithDictionary:task]
                         forKey:[NSString stringWithFormat:@"%@/%@", [task objectForKey:@"task_type"], [task objectForKey:@"task_id"]]];
      }
      _taskTotal++;
    }
    
  }
  return YES;
}

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
  return _taskTotal>0?2:0;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
  if (_taskTotal > 0) {
    return index ? (_taskTotal-_taskError) : _taskError;
  }
  
  return 0;
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
  return index%2?COLORPIEGREEN:COLORPIERED;
}

@end
