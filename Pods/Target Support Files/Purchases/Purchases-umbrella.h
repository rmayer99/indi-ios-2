#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Purchases.h"
#import "RCEntitlement.h"
#import "RCIntroEligibility.h"
#import "RCOffering.h"
#import "RCPurchaserInfo.h"
#import "RCPurchases.h"

FOUNDATION_EXPORT double PurchasesVersionNumber;
FOUNDATION_EXPORT const unsigned char PurchasesVersionString[];

