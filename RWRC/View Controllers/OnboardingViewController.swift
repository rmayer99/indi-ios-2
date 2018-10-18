//
//  OnboardingViewController.swift
//  RWRC
//
//  Created by Ruben Mayer on 8/28/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit
import paper_onboarding
import PKHUD
import FirebaseFirestore

class OnboardingViewController: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    let onboarding = PaperOnboarding()
    onboarding.dataSource = self
    onboarding.delegate = self
    onboarding.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(onboarding)
    
    for attribute: NSLayoutConstraint.Attribute in [.left, .right, .top, .bottom] {
      let constraint = NSLayoutConstraint(item: onboarding,
                                          attribute: attribute,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: attribute,
                                          multiplier: 1,
                                          constant: 0)
      view.addConstraint(constraint)
    }
  }
  
  func onboardingItem(at index: Int) -> OnboardingItemInfo {
    
    return [
      OnboardingItemInfo(informationImage: UIImage(named: "indiTransparent")!,
                         title: "Indi Bot",
                         description: "Your personal fitness companion",
                         pageIcon: UIImage(),
                         color: UIColor.white,
                         titleColor: UIColor.black,
                         descriptionColor: UIColor.black,
                         titleFont: UIFont.boldSystemFont(ofSize: 34),
                         descriptionFont: UIFont.systemFont(ofSize: 22)),
      OnboardingItemInfo(informationImage: UIImage(named: "motivationIcon")!,
                         title: "Get Motivated",
                         description: "To acomplish your fitness goals",
                         pageIcon: UIImage(),
                         color: ColorPalette.indiBlue,
                         titleColor: UIColor.white,
                         descriptionColor: UIColor.white,
                         titleFont: UIFont.boldSystemFont(ofSize: 34),
                         descriptionFont: UIFont.systemFont(ofSize: 22)),
      OnboardingItemInfo(informationImage: UIImage(named: "foodIcon")!,
                         title: "Log your Food",
                         description: "Fast and easy to make sure you stay on top of it!",
                         pageIcon: UIImage(),
                         color: UIColor.white,
                         titleColor: UIColor.black,
                         descriptionColor: UIColor.black,
                         titleFont: UIFont.boldSystemFont(ofSize: 34),
                         descriptionFont: UIFont.systemFont(ofSize: 22)),
      OnboardingItemInfo(informationImage: UIImage(named: "workoutIcon")!,
                         title: "Log your Exercise",
                         description: "Get reminders so you stay consistent",
                         pageIcon: UIImage(),
                         color: ColorPalette.indiBlue,
                         titleColor: UIColor.white,
                         descriptionColor: UIColor.white,
                         titleFont: UIFont.boldSystemFont(ofSize: 34),
                         descriptionFont: UIFont.systemFont(ofSize: 22)),
      OnboardingItemInfo(informationImage: UIImage(named: "indiTransparent")!,
                         title: "Loading App",
                         description: "Just one second...",
                         pageIcon: UIImage(),
                         color: UIColor.white,
                         titleColor: UIColor.black,
                         descriptionColor: UIColor.black,
                         titleFont: UIFont.boldSystemFont(ofSize: 34),
                         descriptionFont: UIFont.systemFont(ofSize: 22))
      ][index]
  }
  
  func onboardingItemsCount() -> Int {
    return 5
  }
  
  
  func onboardingDidTransitonToIndex(_ index: Int) {
    currentOnboardingPageIndex = index
    if index == 4 {
      signUpUserAndTransitionToApp()
    }
  }
  
  func signUpUserAndTransitionToApp() {
    HUD.show(.progress)
    NetworkingManager().signUpUser { (success) in
      if success {
        NetworkingManager().setUserInfo(completionHandler: { _ in })
        var channel = Channel(name: "Indi")
        channel.id = UserDataManager.sharedInstance.userId
        let chatVc = ChatViewController(channel: channel)
        Firestore.firestore().collection("channels").document(channel.id!).setData([
          "user" : "UserDataManager.sharedInstance.userId"
        ]) { err in
          if let err = err {
            print("Error adding document: \(err)")
          } else {
            UserDataManager.sharedInstance.didCompleteOnboardingSlides = true
            HUD.hide()
            self.present(NavigationController(chatVc), animated: true)
          }
        }
        
      } else {
        HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: "Are you connected to the internet?"),  delay: 2, completion: { (_) in
          self.signUpUserAndTransitionToApp()
        })
      }
    }
  }
}

var currentOnboardingPageIndex = 0
extension PaperOnboardingDataSource {
  
  func onboardingPageItemColor(at index: Int) -> UIColor {
    return UIColor.lightGray
  }
}
