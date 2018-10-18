//
//  NetworkingManager.swift
//  RWRC
//
//  Created by Ruben Mayer on 8/29/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class NetworkingManager {
  
  var baseUrl: String
  
  init() {
    switch environment {
    case .development:
      baseUrl = "https://indi-dev.herokuapp.com/api/" //"https://httpbin.org/
    case .production, .logInAsUser, .production2:
      baseUrl = "https://indi-prod.herokuapp.com/api/" //"https://httpbin.org/
    }
    
    //    switch environmentSetting {
    //    case .development:
    //      baseUrl = "https://fg-dev.herokuapp.com/api/" //"https://httpbin.org/
    //    case .production:
    //      baseUrl = "https://fgprod.herokuapp.com/api/"
    //    }
  }
  
  private func performPostRequest (endpoint: String, parameters: Parameters, completionHandler: @escaping (_ result: JSON?, _ didPerformSuccessfully: Bool) -> Void) {
    Alamofire.request(baseUrl + endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON
      { response in
        if response.error != nil {
          print("There was an error sending the request: \(String(describing: response.error))")
          completionHandler(nil, true)
        } else {
          if let result = response.result.value {
            let json = JSON(result)
            completionHandler(json, true)
          } else {
            print("Unknown error performing the request. The response was: \(response)")
            completionHandler(nil, true)
          }
        }
    }
  }
  
  private func performGetRequest (endpoint: String, parameters: Parameters, completionHandler: @escaping (_ result: JSON?, _ didPerformSuccessfully: Bool) -> Void) {
    
    Alamofire.request(baseUrl + endpoint, method: .get, parameters: parameters).responseJSON
      { response in
        if response.error != nil {
          print("There was an error sending the request: \(String(describing: response.error))")
          completionHandler(nil, true)
        } else {
          if let result = response.result.value {
            let json = JSON(result)
            completionHandler(json, true)
          } else {
            print("Unknown error performing the request. The response was: \(response)")
            completionHandler(nil, true)
          }
        }
    }
  }
  
  func signUpUser (completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    var parameters : [String:Any] = [:]
    performPostRequest(endpoint: "signUpUser", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      if didPerformSuccessfully && json != nil {
        if self.processUserInfo(json: json!) {
          completionHandler(true)
        } else {
          completionHandler(false)
        }
      } else {
        completionHandler(false)
      }
    })
  }
  
  private func processUserInfo(json: JSON) -> Bool{
    print(json)
    if json["status"].string == "OK" {
      let result = json["result"]
      UserDataManager.sharedInstance.userId = String(result["id"].int!)
      if UserDataManager.sharedInstance.experimentConfigName != result["experiment_id"].string {
        AnalyticsManager().recordEvent(eventName: result["experiment_id"].string ?? "NULL_EXPERIMENT")
      }
      UserDataManager.sharedInstance.experimentConfigName = result["experiment_id"].string
      processExperimentConfigs(json: result["experiment_configs"])
      return true
    } else {
      return false
    }
  }
  
  func setUserInfo (isNewUser: Bool = false, completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    switch environment {
    case .development, .production2, .production:
      if UserDataManager.sharedInstance.userId != nil {
        var parameters = buildUserInfoParameters()
        performPostRequest(endpoint: "userInfo", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
          if didPerformSuccessfully && json != nil {
            print(json)
            if json!["status"].string == "OK" {
              completionHandler(true)
            } else {
              completionHandler(false)
            }
          } else {
            completionHandler(false)
          }
        })
      }
    case .logInAsUser:
      break
    }
  }
  
  private func buildUserInfoParameters() -> Parameters {
    var parameters : Parameters = [:]
    parameters["user_id"] = UserDataManager.sharedInstance.userId
    parameters["fcm_token"] = UserDataManager.sharedInstance.fcmToken
    parameters["push_token"] = UserDataManager.sharedInstance.pushToken
    parameters["purchased_pro"] = UserDataManager.sharedInstance.didPurchaseIndiPro
    parameters["seconds_from_gmt"] = TimeZone.current.secondsFromGMT()
    parameters["timezone_name"] = TimeZone.current.abbreviation()
    parameters["locale"] = Locale.current.regionCode
    parameters["purchases_id"] = UserDataManager.sharedInstance.purchaseManager.appUserID
    print(parameters)
    return parameters
  }
  
  func requestMessageClassification (completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    if UserDataManager.sharedInstance.userId != nil {
      print(UserDataManager.sharedInstance.currentState)
      var parameters : [String:Any] = ["user_id": UserDataManager.sharedInstance.userId, "current_state" :  UserDataManager.sharedInstance.currentState, "purchased_pro" : UserDataManager.sharedInstance.didPurchaseIndiPro]
      performPostRequest(endpoint: "classifyMessages", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
        if didPerformSuccessfully && json != nil {
          print(json)
          if json!["status"].string == "OK" {
            completionHandler(true)
          } else {
            completionHandler(false)
          }
        } else {
          completionHandler(false)
        }
      })
    }
  }
  
  func getConfigData (completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    let parameters: Parameters = ["config_name" : UserDataManager.sharedInstance.experimentConfigName ?? "BASELINE"]
    performGetRequest(endpoint: "experimentConfig", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      print(UserDataManager.sharedInstance.experimentConfigName)
      print(json)
      if didPerformSuccessfully && json != nil {
        if json!["status"].string == "OK" {
          self.processExperimentConfigs(json: json!["result"])
          completionHandler(true)
        } else {
          completionHandler(false)
        }
      } else {
        completionHandler(false)
      }
    })
  }
  
  private func processExperimentConfigs(json: JSON) {
    UserDataManager.sharedInstance.configs.subscriptionOfferingId = json["subscription_offering_id"].string ?? "indiPro-1"
    if let val = json["aggressiveReviewRequest"].bool {
      UserDataManager.sharedInstance.configs.aggressiveReviewRequest = val
    }
    if let val = json["purchasePageSubtitle"].string {
      UserDataManager.sharedInstance.configs.purchasePageSubtitle = val
    }
    if let val = json["purchasePageTopLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePageTopLabel = val
    }
    if let val = json["purchasePageMiddleLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePageMiddleLabel = val
    }
    if let val = json["purchasePageBottomLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePageBottomLabel = val
    }
    if let val = json["purchasePageFreeTrialLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePageFreeTrialLabel = val
    }
    if let val = json["purchasePagePriceLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePagePriceLabel = val
    }
    if let val = json["purchasePageButtonLabel"].string {
      UserDataManager.sharedInstance.configs.purchasePageButtonLabel = val
    }
    if let val = json["activateIndiButtonName"].string {
      UserDataManager.sharedInstance.configs.activateIndiButtonName = val
    }
    if let val = json["includeOnboardingSlides"].bool {
      UserDataManager.sharedInstance.configs.includeOnboardingSlides = val
    }
    if let val = json["monthlyPrice"].double {
      UserDataManager.sharedInstance.configs.monthlyPrice = val
    }
    if let val = json["reviewOn"].bool {
      UserDataManager.sharedInstance.configs.reviewOn = val
    }
    if let val = json["termsAndConditionsText"].string {
      UserDataManager.sharedInstance.configs.termsAndConditionsText = val
    }
    
    if let val = json["discountedOfferingId"].string {
      UserDataManager.sharedInstance.configs.discountedOfferingId = val
    }
    
    if let val = json["discountedStickerUrl"].string {
      UserDataManager.sharedInstance.configs.discountedStickerUrl = val
    }
    
    if let val = json["discountedPurchasePagePriceLabel"].string {
      UserDataManager.sharedInstance.configs.discountedPurchasePagePriceLabel = val
    }
    
    if let val = json["discountedPurchasePageFreeTrialLabel"].string {
      UserDataManager.sharedInstance.configs.discountedPurchasePageFreeTrialLabel = val
    }
    
    if let val = json["discountedMonthlyPrice"].double {
      UserDataManager.sharedInstance.configs.discountedMonthlyPrice = val
    }
    if let val = json["discountedTermsAndConditionsText"].string {
      UserDataManager.sharedInstance.configs.discountedTermsAndConditionsText = val
    }
    if let val = json["discountedPurchasePageButtonLabel"].string {
      UserDataManager.sharedInstance.configs.discountedPurchasePageButtonLabel = val
    }
  }
  
  func sendPurchasedProRequest (completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    if UserDataManager.sharedInstance.userId != nil {
      var parameters : [String:Any] = ["user_id": UserDataManager.sharedInstance.userId, "current_state" :  UserDataManager.sharedInstance.currentState]
      performPostRequest(endpoint: "userPurchasedPro", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
        if didPerformSuccessfully && json != nil {
          print(json)
          if json!["status"].string == "OK" {
            completionHandler(true)
          } else {
            completionHandler(false)
          }
        } else {
          completionHandler(false)
        }
      })
    }
  }
  
  func deleteCaloriesEntry (entryId: Int, completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    var parameters : Parameters = ["entry_id": entryId]
    performPostRequest(endpoint: "deleteCaloriesEntry", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      if didPerformSuccessfully && json != nil {
        print(json)
        if json!["status"].string == "OK" {
          completionHandler(true)
        } else {
          completionHandler(false)
        }
      } else {
        completionHandler(false)
      }
    })
  }
  
  func editCaloriesEntry (entryId: Int, newValue: Int, completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    var parameters : Parameters = ["entry_id": entryId, "new_value": newValue]
    performPostRequest(endpoint: "editCaloriesEntry", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      if didPerformSuccessfully && json != nil {
        print(json)
        if json!["status"].string == "OK" {
          completionHandler(true)
        } else {
          completionHandler(false)
        }
      } else {
        completionHandler(false)
      }
    })
  }
  
  func quickAddCaloriesEntry (caloriesValue: Int, completionHandler: @escaping (_ didPerformSuccessfully: Bool) -> Void) {
    var parameters : Parameters = ["user_id": UserDataManager.sharedInstance.userId, "calories_value": caloriesValue]
    performPostRequest(endpoint: "quickAddCaloriesEntry", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      if didPerformSuccessfully && json != nil {
        print(json)
        if json!["status"].string == "OK" {
          completionHandler(true)
        } else {
          completionHandler(false)
        }
      } else {
        completionHandler(false)
      }
    })
  }
  
  func getCaloriesEntriesForDateRange (dateIndex: Int, completionHandler: @escaping (_ didPerformSuccessfully: Bool, _ journalEntries: [JournalEntry]) -> Void) {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    var components = DateComponents()
    components.day = dateIndex
    let startDate = Calendar.current.date(byAdding: components, to: startOfDay)!
    components.second = -1
    components.day = dateIndex + 1
    let endDate = Calendar.current.date(byAdding: components, to: startOfDay)!
    print(startDate)
    print(endDate)
    let parameters: Parameters = ["user_id" : UserDataManager.sharedInstance.userId, "start_date": startDate, "end_date": endDate]
    performGetRequest(endpoint: "getCaloriesEntriesForDateRange", parameters: parameters, completionHandler: { json, didPerformSuccessfully in
      print(json)
      if didPerformSuccessfully && json != nil {
        if json!["status"].string == "OK" {
          self.processExperimentConfigs(json: json!["result"])
          completionHandler(true, [])
        } else {
          completionHandler(false, [])
        }
      } else {
        completionHandler(false, [])
      }
    })
  }
  
  func processCaloriesEntries(json: JSON) {
  
  }
  
}
