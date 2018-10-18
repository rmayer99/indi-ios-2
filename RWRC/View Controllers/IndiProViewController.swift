//
//  IndiProViewController.swift
//  RWRC
//
//  Created by Ruben Mayer on 9/12/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit
import Purchases
import PKHUD
import Kingfisher


class IndiProViewController: UIViewController {
  
  
  let dm = UserDataManager.sharedInstance
  
  
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var termsTextView: UITextView!
  
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var topLabel: UILabel!
  @IBOutlet weak var middleLabel: UILabel!
  @IBOutlet weak var bottomLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var freeTrialLabel: UILabel!
  @IBOutlet weak var allProductsButton: UIButton!
  @IBOutlet weak var termsAndConditionsLabel: UILabel!
  @IBOutlet weak var saleStickerImage: UIImageView!
  
  @IBOutlet weak var saleStickerHeightConstraint: NSLayoutConstraint?
  
  
  //@IBOutlet weak var buyButtonHeight: NSLayoutConstraint!
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.isNavigationBarHidden = false
    dm.purchaseManager.delegate = self
    allProductsButton.isHidden = true
    AnalyticsManager().recordEvent(eventName: AnalyticsManager.AnalyticsEvents.didOpenPurchaseView)
    topLabel.text = dm.configs.purchasePageTopLabel
    middleLabel.text = dm.configs.purchasePageMiddleLabel
    bottomLabel.text = dm.configs.purchasePageBottomLabel
    subtitleLabel.text = dm.configs.purchasePageSubtitle
    
    if dm.discountActivated == false {
      freeTrialLabel.text = dm.configs.purchasePageFreeTrialLabel
      buyButton.setTitle(dm.configs.purchasePageButtonLabel, for: .normal)
    } else {
      freeTrialLabel.text = dm.configs.discountedPurchasePageFreeTrialLabel
      buyButton.setTitle(dm.configs.discountedPurchasePageButtonLabel, for: .normal)
    }
    
    NotificationCenter.default.addObserver(self, selector:#selector(loadViewFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
    
  }
  
  override func viewWillLayoutSubviews() {
    buyButton.layer.cornerRadius = 20
    if dm.discountActivated == false {
      saleStickerHeightConstraint?.setMultiplier(multiplier: 0.01)
      saleStickerImage.isHidden = true
    } else {
      saleStickerImage.isHidden = false
      saleStickerHeightConstraint?.setMultiplier(multiplier: 0.85)
      saleStickerImage.kf.setImage(with: URL(string: dm.configs.discountedStickerUrl), placeholder: UIImage(named: "discountStickerPlaceholder.png"))
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.isNavigationBarHidden = true
    
    var discountedProduct = dm.discountedPurchaseProduct
    var product = dm.purchaseProduct
    if discountedProduct == nil {
      dm.purchaseManager.entitlements { entitlements in
        guard let discountedPro = entitlements?["indiPro"] else { return }
        print(self.dm.configs.subscriptionOfferingId)
        guard let discountedMonthly = discountedPro.offerings[self.dm.configs.discountedOfferingId] else { return }
        guard let _ = discountedMonthly.activeProduct else { return }
        discountedProduct = discountedMonthly.activeProduct
        
        guard let pro = entitlements?["indiPro"] else { return }
        print(self.dm.configs.subscriptionOfferingId)
        guard let monthly = pro.offerings[self.dm.configs.subscriptionOfferingId] else { return }
        guard let _ = monthly.activeProduct else { return }
        product = monthly.activeProduct
        
        if self.dm.discountActivated != true {
          self.setUpPurchaseInfoFromConfig(product: product!)
        } else {
          self.setUpPurchaseInfoFromConfig(product: discountedProduct!)
          self.adjustPriceLabelForDiscountedPurchase(regularProduct: product!, discountedProduct: discountedProduct!)
        }
      }
    } else {
      if self.dm.discountActivated != true {
        self.setUpPurchaseInfoFromConfig(product: product!)
      } else {
        self.setUpPurchaseInfoFromConfig(product: discountedProduct!)
        self.adjustPriceLabelForDiscountedPurchase(regularProduct: product!, discountedProduct: discountedProduct!)
      }
    }
  }
  
  @objc func loadViewFromBackground() {
    let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (_) in
      
      self.viewDidLoad()
      self.viewWillLayoutSubviews()
      self.viewWillAppear(false)
    })
  }
  
  func setUpPurchaseInfoFromConfig(product : SKProduct) {
    var price = NSDecimalNumber(value: UserDataManager.sharedInstance.configs.monthlyPrice)
    var fullPrice = product.price
    if price == 0 {
      price = product.price
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = product.priceLocale
    let priceString = formatter.string(from: price)
    let indexOfPrice = self.dm.configs.purchasePagePriceLabel.firstIndex(of: "<")?.encodedOffset
    let priceAttributedText = NSMutableAttributedString(string: self.dm.configs.purchasePagePriceLabel.replacingOccurrences(of: "<price>", with: priceString ?? "$1.99"))
    priceAttributedText.addAttributes([NSAttributedString.Key.foregroundColor : ColorPalette.indiBlue, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)], range: NSRange(location: indexOfPrice ?? 5, length: priceString?.length ?? 5))
    self.priceLabel.attributedText = priceAttributedText
    
    var subscriptionPeriod = "month"
    if #available(iOS 11.2, *), product.subscriptionPeriod! != nil {
      switch product.subscriptionPeriod!.unit {
      case .day:
        subscriptionPeriod = "day"
      case  .year:
        subscriptionPeriod = "year"
      default:
        break
      }
    }
    let disclosure = NSMutableAttributedString(string: "Buy purchasing Indi Fitness Bot Pro, you agree to our Terms of Service and Privacy Policy. The subscription is " + (formatter.string(from: product.price) ?? "$2") + " per " + subscriptionPeriod + ". Your subscription will automatically renew within 24 hours prior to the end of the current period.\n\nYou can manage your subscription at any time by going to your account settings after purchasing. Any unused portion of your free trial will be forfeited when you purchase a subscription.")
    disclosure.addAttribute(.link, value: "https://docs.google.com/document/d/1zxZ9JwwPewPNVlZ0XaBeIafYy1JSO3JyxE6fzUU8VjY/edit?usp=sharing", range: NSRange(location: 54, length: 16))
    disclosure.addAttribute(.link, value: "https://docs.google.com/document/d/1f9rhxDDDsU2zUkKUD5iyXo7lMb3YwBca6A5l7ctN4tU/edit?usp=sharing", range: NSRange(location: 75, length: 14))
    let paragraphCentered = NSMutableParagraphStyle()
    paragraphCentered.alignment = .center
    disclosure.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphCentered], range: NSRange(location: 0, length: 19))
    self.termsTextView.attributedText = disclosure
    self.termsTextView.textColor = UIColor.darkGray
    self.termsTextView.textAlignment = .center
    
    self.termsAndConditionsLabel.text = UserDataManager.sharedInstance.configs.termsAndConditionsText.replacingOccurrences(of: "<price>", with: formatter.string(from: product.price) ?? "$24")
  }
  
  func adjustPriceLabelForDiscountedPurchase(regularProduct: SKProduct, discountedProduct: SKProduct) {
    var regularPrice = regularProduct.price
    var discountedPrice = discountedProduct.price
    if dm.configs.monthlyPrice != 0 {
      regularPrice = NSDecimalNumber(value: UserDataManager.sharedInstance.configs.monthlyPrice)
    }
    if dm.configs.discountedMonthlyPrice != 0 {
      discountedPrice = NSDecimalNumber(value: UserDataManager.sharedInstance.configs.discountedMonthlyPrice)
    }
    
    if dm.configs.discountedMonthlyPrice != 0 {
      discountedPrice = NSDecimalNumber(value: UserDataManager.sharedInstance.configs.discountedMonthlyPrice)
    }
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = discountedProduct.priceLocale
    let regularPriceString = formatter.string(from: regularPrice)
    let discountedPriceString = formatter.string(from: discountedPrice)
    let indexOfDiscountedPrice = self.dm.configs.discountedPurchasePagePriceLabel.firstIndex(of: "<")?.encodedOffset
    
    var edditedPriceString = self.dm.configs.discountedPurchasePagePriceLabel.replacingOccurrences(of: "<discountedPrice>", with: discountedPriceString ?? "$1.99").replacingOccurrences(of: "<regularPrice>", with: regularPriceString ?? "$3.90")
    let startIndexOfRegularPriceInfo = edditedPriceString.firstIndex(of: "(")!.encodedOffset
    
    let priceAttributedText = NSMutableAttributedString(string: edditedPriceString)
    priceAttributedText.addAttributes([NSAttributedString.Key.foregroundColor : ColorPalette.indiBlue, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)], range: NSRange(location: indexOfDiscountedPrice ?? 5, length: discountedPriceString?.length ?? 5))
    var parethesisTerm = edditedPriceString.slice(from: "(", to: ")" )
    priceAttributedText.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.darkGray], range: NSRange(location: startIndexOfRegularPriceInfo ?? 5, length: parethesisTerm!.length + 2 ))
    
    self.priceLabel.attributedText = priceAttributedText
    
    var subscriptionPeriod = "month"
    if #available(iOS 11.2, *), discountedProduct.subscriptionPeriod! != nil {
      switch discountedProduct.subscriptionPeriod!.unit {
      case .day:
        subscriptionPeriod = "day"
      case  .year:
        subscriptionPeriod = "year"
      default:
        break
      }
    }
    let disclosure = NSMutableAttributedString(string: "Buy purchasing Indi Fitness Bot Pro, you agree to our Terms of Service and Privacy Policy. The subscription is " + (formatter.string(from: discountedProduct.price) ?? "$2") + " per " + subscriptionPeriod + ". Your subscription will automatically renew within 24 hours prior to the end of the current period.\n\nYou can manage your subscription at any time by going to your account settings after purchasing. Any unused portion of your free trial will be forfeited when you purchase a subscription.")
    disclosure.addAttribute(.link, value: "https://docs.google.com/document/d/1zxZ9JwwPewPNVlZ0XaBeIafYy1JSO3JyxE6fzUU8VjY/edit?usp=sharing", range: NSRange(location: 54, length: 16))
    disclosure.addAttribute(.link, value: "https://docs.google.com/document/d/1f9rhxDDDsU2zUkKUD5iyXo7lMb3YwBca6A5l7ctN4tU/edit?usp=sharing", range: NSRange(location: 75, length: 14))
    let paragraphCentered = NSMutableParagraphStyle()
    paragraphCentered.alignment = .center
    disclosure.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphCentered], range: NSRange(location: 0, length: 19))
    self.termsTextView.attributedText = disclosure
    self.termsTextView.textColor = UIColor.darkGray
    self.termsTextView.textAlignment = .center
    
    
    self.termsAndConditionsLabel.text = UserDataManager.sharedInstance.configs.discountedTermsAndConditionsText.replacingOccurrences(of: "<price>", with: formatter.string(from: discountedProduct.price) ?? "$24")
    
  }
  
  
  
  
  override func viewWillDisappear(_ animated: Bool) {
    self.navigationController?.isNavigationBarHidden = false
  }
  
  
  
  @IBAction func didPressRestoreButton(_ sender: Any) {
    dm.purchaseManager.restoreTransactionsForAppStoreAccount()
  }
  
  @IBAction func didPressBackButton(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func didPressBuyButton(_ sender: Any) {
    HUD.show(HUDContentType.labeledProgress(title:"  Contacting app store...  ", subtitle: ""))
    dm.purchaseManager.entitlements { entitlements in
      guard let pro = entitlements?["indiPro"] else { return }
      guard let monthly = pro.offerings[self.dm.configs.subscriptionOfferingId] else { return }
      var offering = pro.offerings[self.dm.configs.subscriptionOfferingId]
      
      if self.dm.discountActivated == true {
        guard let monthly = pro.offerings[self.dm.configs.discountedOfferingId] else { return }
        offering = pro.offerings[self.dm.configs.discountedOfferingId]
      }
      
      guard let product = offering!.activeProduct else { return }
      
      AnalyticsManager().recordEvent(eventName: AnalyticsManager.AnalyticsEvents.initiatedPurchase)
      self.dm.purchaseManager.makePurchase(product)
    }
  }
  
  func didPurchaseSuccessfully() {
    AnalyticsManager().recordPurchase()
    UserDataManager.sharedInstance.didPurchaseIndiPro = true
    HUD.show(HUDContentType.labeledProgress(title: "Activating Indi...", subtitle: ""))
    sendPurchasedProRequest()
    
  }
  
  func sendPurchasedProRequest(retryAttempts: Int = 0) {
    NetworkingManager().sendPurchasedProRequest { (didCompleteSuccessfully) in
      if didCompleteSuccessfully {
        HUD.hide()
        if let chatVC = self.navigationController?.getPreviousViewController() as? ChatViewController {
          chatVC.didPurchasePro()
        }
        self.navigationController?.popViewController(animated: true)
      } else if retryAttempts < 3 {
        self.sendPurchasedProRequest(retryAttempts: retryAttempts + 1)
      } else {
        HUD.hide()
        HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: "Are you connected to the internet?"),  delay: 2, completion: nil)
      }
    }
  }
  
  @IBAction func didPressAllProductsButton(_ sender: Any) {
    
  }
  
  
}

extension IndiProViewController: RCPurchasesDelegate {
  func purchases(_ purchases: RCPurchases, completedTransaction transaction: SKPaymentTransaction, withUpdatedInfo purchaserInfo: RCPurchaserInfo) {
    if purchaserInfo.activeEntitlements.first == "indiPro" {
      self.didPurchaseSuccessfully()
    }
  }
  
  func purchases(_ purchases: RCPurchases, receivedUpdatedPurchaserInfo purchaserInfo: RCPurchaserInfo) {
    print("Received Updated Purchase Info")
  }
  
  func purchases(_ purchases: RCPurchases, failedToUpdatePurchaserInfoWithError error: Error) {
    HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: "Are you connected to the internet?"),  delay: 2, completion: nil)
  }
  
  func purchases(_ purchases: RCPurchases, failedTransaction transaction: SKPaymentTransaction, withReason failureReason: Error) {
    
    HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: "Are you connected to the internet?"),  delay: 2, completion: nil)
  }
  
  func purchases(_ purchases: RCPurchases, restoredTransactionsWith purchaserInfo: RCPurchaserInfo) {
    if purchaserInfo.activeEntitlements.first == "indiPro" {
      //AnalyticsEvents.recordEvent(AnalyticsEvents.restoredTrueGasPro);
      self.didPurchaseSuccessfully()
    }
  }
  
  func purchases(_ purchases: RCPurchases, failedToRestoreTransactionsWithError error: Error) {
    HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: "Are you connected to the internet?"),  delay: 2, completion: nil)
    
  }
}

