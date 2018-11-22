//
//  AnalyticsManager.swift
//  RWRC
//
//  Created by Ruben Mayer on 9/20/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
import AppsFlyerLib
import FirebaseAnalytics
import Amplitude_iOS

class AnalyticsManager {
  
  struct AnalyticsEvents {
    static let purchased = "purchased"
    static let initiatedPurchase = "initiatedPurchase"
    static let openedApp = "openedApp"
    static let queriedCalories = "queriedCalories"
    static let sentMessage = "sentMessage"
    static let didOpenPurchaseView = "didOpenPurchaseView"
  }
  
  func recordPurchase() {
    if UserDataManager.sharedInstance.hasRecordedPurchase != true {
      AppsFlyerTracker.shared().trackEvent(AnalyticsEvents.purchased, withValues: [:])
      UserDataManager.sharedInstance.hasRecordedPurchase = true
      recordEvent(eventName: AnalyticsEvents.purchased)
    }
  }
  
  func recordEvent(eventName: String) {
    AppsFlyerTracker.shared().trackEvent(eventName, withValues: [:])
    Analytics.logEvent(eventName, parameters: [:])
    Amplitude.instance().logEvent(eventName)
  }
}
