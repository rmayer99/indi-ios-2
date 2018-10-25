/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Fabric
import Crashlytics
import FacebookCore
import AppsFlyerLib
import Purchases
import Amplitude_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerTrackerDelegate {
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    switch environment {
    case .development:
      let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
      let fileopts = FirebaseOptions(contentsOfFile: filePath!)
      FirebaseApp.configure(options: fileopts!)
    case .production2:
      let filePath = Bundle.main.path(forResource: "GoogleService-Info-Prod-2", ofType: "plist")
      let fileopts = FirebaseOptions(contentsOfFile: filePath!)
      FirebaseApp.configure(options: fileopts!)
    case .production, .logInAsUser:
      let filePath = Bundle.main.path(forResource: "GoogleService-Info-Prod", ofType: "plist")
      let fileopts = FirebaseOptions(contentsOfFile: filePath!)
      FirebaseApp.configure(options: fileopts!)
    }
    AppController.shared.show(in: UIWindow(frame: UIScreen.main.bounds))
    Amplitude.instance().initializeApiKey("f63a15b4255f468a1484886588780a26")
    UNUserNotificationCenter.current().delegate = self
    // For iOS 10 data message (sent via FCM)
    Fabric.with([Crashlytics.self])
    Fabric.with([Answers.self])
    AppEventsLogger.activate(application)
    
    
    Messaging.messaging().delegate = self as MessagingDelegate
    
    AppsFlyerTracker.shared().appsFlyerDevKey = "zYA97HirswJMEnmqwgWKqV";
    AppsFlyerTracker.shared().appleAppID = "1434796554"
    AppsFlyerTracker.shared().delegate = self
    
    switch environment {
    case .production, .logInAsUser:
      UserDataManager.sharedInstance.purchaseManager = RCPurchases(apiKey: "jJQWhqiOiijzDQjXFUcjppWLdKYjNrps")
    case .production2, .development:
      UserDataManager.sharedInstance.purchaseManager = RCPurchases(apiKey: "gayWKufLcVZgNUonpizTODLuuSfykMaf")
    }
    
    
    
    UserDataManager.sharedInstance.purchaseManager.delegate = self
    
    // #ifdef DEBUG AppsFlyerTracker.shared().isDebug = true
    // #endifCopy
    
    if UserDataManager.sharedInstance.userId != nil {
      NetworkingManager().setUserInfo(completionHandler: { _ in })
    }
    AnalyticsManager().recordEvent(eventName: AnalyticsManager.AnalyticsEvents.openedApp)
    return true
  }
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return .portrait
  }
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    var token = ""
    for i in 0..<deviceToken.count {
      token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
    }
    if token != UserDataManager.sharedInstance.pushToken {
      UserDataManager.sharedInstance.pushToken = token
      UserDataManager.sharedInstance.pushTokenData = deviceToken
      NetworkingManager().setUserInfo(completionHandler: { (didCompleteSuccessfully) in
        if didCompleteSuccessfully {
          print("did upload user token")
        } else {
          print("error uploading user token")
        }
        
      })
    }
    //Intercom.setDeviceToken(deviceToken)
  }
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    print("Firebase registration token: \(fcmToken)")
    
    UserDataManager.sharedInstance.fcmToken = fcmToken
    if UserDataManager.sharedInstance.userId != nil {
      NetworkingManager().setUserInfo(completionHandler: { (didCompleteSuccessfully) in
        if didCompleteSuccessfully {
          print("Did upload user token")
        }
      })
    }
    
  }
  
}


@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
  
  // Receive displayed notifications for iOS 10 devices.
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    // Print message ID.
    print("Message ID: \(userInfo["gcm.message_id"]!)")
    
    // Print full message.
    print("%@", userInfo)
    
  }
  
}

extension AppDelegate : MessagingDelegate {
  // Receive data message on iOS 10 devices.
  func application(received remoteMessage: MessagingRemoteMessage) {
    print("%@", remoteMessage.appData)
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    AppsFlyerTracker.shared().trackAppLaunch()
  }
}


extension AppDelegate: RCPurchasesDelegate {
  func purchases(_ purchases: RCPurchases, completedTransaction transaction: SKPaymentTransaction, withUpdatedInfo purchaserInfo: RCPurchaserInfo) {
    //handlePurchaserInfo(purchaserInfo)
  }
  
  func purchases(_ purchases: RCPurchases, receivedUpdatedPurchaserInfo purchaserInfo: RCPurchaserInfo) {
    if purchaserInfo.activeEntitlements.first == "indiPro" {
      UserDataManager.sharedInstance.didPurchaseIndiPro = true
      AnalyticsManager().recordPurchase()
    } else {
      switch environment {
      case .production, .logInAsUser, .production2:
        UserDataManager.sharedInstance.didPurchaseIndiPro = false
      case .development:
        UserDataManager.sharedInstance.didPurchaseIndiPro = true
      }
    }
  }
  
  func purchases(_ purchases: RCPurchases, failedToUpdatePurchaserInfoWithError error: Error) {
    //showError(error)
  }
  
  func purchases(_ purchases: RCPurchases, failedTransaction transaction: SKPaymentTransaction, withReason failureReason: Error) {
    //showError(failureReason)
  }
  
  func purchases(_ purchases: RCPurchases, restoredTransactionsWith purchaserInfo: RCPurchaserInfo) {
    //handlePurchaserInfo(purchaserInfo)
  }
  
  func purchases(_ purchases: RCPurchases, failedToRestoreTransactionsWithError error: Error) {
    //showError(failureReason)
  }
}



