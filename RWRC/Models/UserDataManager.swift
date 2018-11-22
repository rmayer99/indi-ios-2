//
//  File.swift
//  RWRC
//
//  Created by Ruben Mayer on 8/28/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
import Purchases
import Kingfisher
import UIKit

class UserDataManager {
  static let sharedInstance = UserDataManager()
  let defaults = UserDefaults.standard
  var purchaseManager : RCPurchases!
  var purchaseProduct : SKProduct? = nil
  var discountedPurchaseProduct : SKProduct? = nil

  
  var currentState : Int {
    didSet {
      defaults.set(currentState, forKey: "currentState")
    }
  }
  
  var  currentStateSendDate : Int {
    didSet {
      defaults.set(currentStateSendDate, forKey: "currentStateSendDate")
    }
  }
  
  var userId : String? {
    didSet {
      defaults.set(userId, forKey: "userId")
    }
  }
  
  var didCompleteOnboardingSlides = false {
    didSet {
      defaults.set(didCompleteOnboardingSlides, forKey: "didCompleteOnboardingSlides")
    }
  }
  
  var fcmToken : String? {
    didSet {
      defaults.set(fcmToken, forKey: "fcmToken")
    }
  }
  
  var pushToken : String? {
    didSet {
      defaults.set(pushToken, forKey: "pushToken")
    }
  }
  
  var pushTokenData : Data? {
    didSet {
      defaults.set(pushTokenData, forKey: "pushTokenData")
    }
  }
  var hasReceivedPushNotificationsRequest : Bool? {
    didSet {
      defaults.set(hasReceivedPushNotificationsRequest, forKey: "hasReceivedPushNotificationsRequest")
    }
  }
  
  var didPurchaseIndiPro : Bool? {
    didSet {
      defaults.set(didPurchaseIndiPro, forKey: "didPurchaseIndiPro")
    }
  }
  
  var hasRecordedPurchase : Bool? {
    didSet {
      defaults.set(hasRecordedPurchase, forKey: "hasRecordedPurchase")
    }
  }
  
  var experimentConfigName : String? {
    didSet {
      defaults.set(experimentConfigName, forKey: "experimentConfigName")
    }
  }
  
  var hasAskedForReview : Bool? {
    didSet {
      defaults.set(hasAskedForReview, forKey: "hasAskedForReview")
    }
  }
  
  var discountActivated : Bool? {
    didSet {
      defaults.set(discountActivated, forKey: "discountActivated")
    }
  }
  
  
  var preferredWeightDenomination : String! {
    didSet {
      defaults.set(preferredWeightDenomination, forKey: "preferredWeightDenomination" )
    }
  }
  
  var preferredHeightDenomination : String! {
    didSet {
      defaults.set(preferredHeightDenomination, forKey: "preferredHeightDenomination")
    }
  }
  
  var didProcessCaloriesGoal: Bool! {
    didSet {
      defaults.set(didProcessCaloriesGoal, forKey: "didProcessCaloriesGoal")
    }
  }
  
  init() {
    didCompleteOnboardingSlides = defaults.bool(forKey: "didCompleteOnboardingSlides")
    userId = defaults.string(forKey: "userId")
    fcmToken = defaults.string(forKey: "fcmToken")
    pushToken = defaults.string(forKey: "pushToken")
    pushTokenData = defaults.data(forKey: "pushTokenData")
    hasReceivedPushNotificationsRequest = defaults.bool(forKey: "hasReceivedPushNotificationsRequest")
    currentState = defaults.integer(forKey: "currentState")
    didPurchaseIndiPro = defaults.bool(forKey: "didPurchaseIndiPro")
    currentStateSendDate = defaults.integer(forKey: "currentStateSendDate")
    hasRecordedPurchase = defaults.bool(forKey: "hasRecordedPurchase")
    experimentConfigName = defaults.string(forKey: "experimentConfigName")
    hasAskedForReview = defaults.bool(forKey: "hasAskedForReview")
    discountActivated = defaults.bool(forKey: "discountActivated")
    preferredWeightDenomination = defaults.string(forKey: "preferredWeightDenomination") ?? "pounds"
    preferredHeightDenomination = defaults.string(forKey: "preferredHeightDenomination") ?? " feet"
    didProcessCaloriesGoal = defaults.bool(forKey: "didProcessCaloriesGoal") ?? false
    
    if let configData = UserDefaults.standard.value(forKey:"configs") as? Data {
      do {
        configs = try PropertyListDecoder().decode(Configs.self, from: configData)
      } catch {
        configs = Configs.init(subscriptionOfferingId: "indiPro-1",
                               aggressiveReviewRequest : false,
                               purchasePageSubtitle: "Your Personal\nFitness Companion",
                               purchasePageTopLabel: "Log Calories",
                               purchasePageMiddleLabel: "Track Workouts",
                               purchasePageBottomLabel: "Get Motivation",
                               purchasePageFreeTrialLabel: "3 day Free Trial",
                               purchasePagePriceLabel: "only <price> per month",
                               purchasePageButtonLabel: "Try Indi",
                               activateIndiButtonName: "Activate Indi",
                               includeOnboardingSlides: true,
                               monthlyPrice: 0,
                               reviewOn: false,
                               termsAndConditionsText: "terms and conditions below",
                               discountedOfferingId : "",
                               discountedPurchasePagePriceLabel : "",
                               discountedPurchasePageFreeTrialLabel : "",
                               discountedMonthlyPrice : 0,
                               discountedStickerUrl : "",
                               discountedTermsAndConditionsText : "",
                               discountedPurchasePageButtonLabel : "try Indi",
                               shouldIncludeCaloriesGoal : true
        )
        
        
      }
    } else {
      configs = Configs.init(subscriptionOfferingId: "indiPro-1",
                             aggressiveReviewRequest : false,
                             purchasePageSubtitle: "Your Personal\nFitness Companion",
                             purchasePageTopLabel: "Log Calories",
                             purchasePageMiddleLabel: "Track Workouts",
                             purchasePageBottomLabel: "Get Motivation",
                             purchasePageFreeTrialLabel: "3 day Free Trial",
                             purchasePagePriceLabel: "only <price> per month",
                             purchasePageButtonLabel: "Try Indi",
                             activateIndiButtonName: "Activate Indi",
                             includeOnboardingSlides: true,
                             monthlyPrice: 0,
                             reviewOn: false,
                             termsAndConditionsText: "terms and conditions below",
                             discountedOfferingId : "",
                             discountedPurchasePagePriceLabel : "",
                             discountedPurchasePageFreeTrialLabel : "",
                             discountedMonthlyPrice : 0,
                             discountedStickerUrl : "",
                             discountedTermsAndConditionsText : "",
                             discountedPurchasePageButtonLabel : "try Indi",
                             shouldIncludeCaloriesGoal: true)
    }
    
    if currentState == 0 {
      currentState = 1
    }
  }
  
  struct Configs : Codable {
    var subscriptionOfferingId : String
    var aggressiveReviewRequest : Bool
    var purchasePageSubtitle : String
    var purchasePageTopLabel : String
    var purchasePageMiddleLabel : String
    var purchasePageBottomLabel : String
    var purchasePageFreeTrialLabel : String
    var purchasePagePriceLabel : String
    var purchasePageButtonLabel : String
    var activateIndiButtonName : String
    var includeOnboardingSlides : Bool
    var monthlyPrice : Double
    var reviewOn : Bool
    var termsAndConditionsText : String
    var discountedOfferingId : String
    var discountedPurchasePagePriceLabel : String
    var discountedPurchasePageFreeTrialLabel : String
    var discountedMonthlyPrice : Double
    var discountedStickerUrl : String
    var discountedTermsAndConditionsText : String
    var discountedPurchasePageButtonLabel : String
    var shouldIncludeCaloriesGoal : Bool
  }
  
  func getConfigData(retryAttempts: Int = 0) {
    NetworkingManager().getConfigData { (didCompleteSuccessfully) in
      if !didCompleteSuccessfully && retryAttempts < 3 {
        self.getConfigData(retryAttempts: retryAttempts + 1)
      } else if didCompleteSuccessfully {
        self.defaults.set(try? PropertyListEncoder().encode(self.configs), forKey:"configs")
        print("successfully downloaded experiment config data")
        self.purchaseManager.entitlements { entitlements in
          guard let pro = entitlements?["indiPro"] else { return }
          guard let monthly = pro.offerings[self.configs.subscriptionOfferingId] else { return }
          guard let product = monthly.activeProduct else { return }
          
          guard let discounted = pro.offerings[self.configs.discountedOfferingId] else { return }
          guard let discountedProduct = discounted.activeProduct else { return }
          self.purchaseProduct = product
          self.discountedPurchaseProduct = discountedProduct
          
          UIImageView().kf.setImage(with: URL(string: self.configs.discountedStickerUrl))
          
        }
        
      }
    }
  }
  
  func shouldDisplayCaloriesGoal() -> Bool {
    return didProcessCaloriesGoal && didPurchaseIndiPro == true
  }
  
  var configs : Configs
}
