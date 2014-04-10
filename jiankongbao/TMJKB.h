//
//  TMJKB.h
//  jiankongbao
//
//  Created by Tomasen on 2/20/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "KeychainItem.h"
#import "XYPieChart.h"


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define COLORPIERED     UIColorFromRGB(0xE74C3C)
#define COLORPIEGREEN   UIColorFromRGB(0x2ECC71)

enum FLAG {
	NOPURCHARSEOPTION = 0x01000000
};

@protocol TMJKBPurchaseDelegate <NSObject>

@required
- (void)purchaseFinished:(BOOL)noAds withMessage:(NSString *)msg;

@end

@interface TMJKB : NSObject <XYPieChartDataSource, SKPaymentTransactionObserver, SKProductsRequestDelegate>
{
  NSDictionary* taskList_;
  NSString*     lastAuthStr_;
}

+(TMJKB *)_instance;
-(BOOL) procJSON:(NSData*)data kind:(NSString*)task;
-(void) fetchTaskList:(NSString*)authStr completeHandler:(void (^)(NSInteger statusCode))handler;
-(void) restorePreviousTransaction:(id)sender;
-(void) purchaseNoAds:(id)sender;
-(NSString*) getAuthStr;

-(BOOL) shouldShowAds;
-(BOOL) shouldShowPurchaseOption;

@property(nonatomic, assign)    UInt32          flag;
@property(nonatomic, assign)    BOOL            noAds;
@property (nonatomic, retain)   KeychainItem*   keychain;
@property(nonatomic, readonly)  NSInteger       taskTotal;
@property(nonatomic, readonly)  NSInteger       taskError;
@property(nonatomic, readonly)  NSMutableDictionary*  faultyTasks;
@property(nonatomic, assign) id <TMJKBPurchaseDelegate> purchaseDelegate;
@end
