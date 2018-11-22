//
//  Utils.swift
//  RWRC
//
//  Created by Ruben Mayer on 8/28/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Contacts


//Mark functions
func dateFromString(str: String?) -> Date? {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
  dateFormatter.timeZone = TimeZone(abbreviation: "UTC")!
  if str != nil {
    let date = dateFormatter.date(from: str!)
    return date
  } else {
    return nil
  }
}

func stringFromDate(date: Date?) -> String? {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
  if date != nil {
    return formatter.string(from: date!)
  } else {
    return nil
  }
}

func utcDateToLocalTime(date: Date?) -> Date? {
  if date != nil {
    let tz : TimeZone = TimeZone.current
    let seconds : Int = tz.secondsFromGMT(for: date!)
    return Date(timeInterval: -1 * TimeInterval(seconds), since: date!)
  } else {
    return nil
  }
  
  // create dateFormatter with UTC time format
}

func formatDateForDisplay(date: Date?) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM dd yyyy"
  if date != nil {
    return formatter.string(from: date!)
  } else {
    return ""
  }
}

func getUTCdate() -> String {
  let utcDate = Date()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMddHHmmss"
  formatter.timeZone = TimeZone(secondsFromGMT:0)
  let defaultTimeZoneStr = formatter.string(from: utcDate)
  return defaultTimeZoneStr
}

func createBoundsGivenProportions(designScreenHeight:CGFloat, designScreenWidth: CGFloat, dy:CGFloat, dx: CGFloat, h: CGFloat, w: CGFloat, aspectRatio : CGFloat? = nil) -> CGRect {
  let realScreenWidth = UIScreen.main.bounds.width
  var realScreenHeight = UIScreen.main.bounds.height
  var estimatedWidth = w/designScreenWidth * realScreenWidth
  var estimatedHeight =  h/designScreenHeight * realScreenHeight
  var estimatedDx = dx/designScreenWidth * realScreenWidth
  var estimatedDy = dy/designScreenHeight * realScreenHeight
  
  if aspectRatio != nil { //aspectRation = w/h
    let newHeight = estimatedWidth / aspectRatio!
    estimatedDy += (estimatedHeight - newHeight)/2
    estimatedHeight = newHeight
  }
  
  return CGRect(x: estimatedDx , y: estimatedDy , width: estimatedWidth, height: estimatedHeight)
}

//    if UIScreen.main.nativeBounds.height == 2436 {//is iphone X
//        realScreenHeight -= 160
//        return CGRect(x: dx/designScreenWidth * realScreenWidth, y: dy/designScreenHeight * (realScreenHeight + 100) + 10, width: w/designScreenWidth * realScreenWidth, height: h/designScreenHeight * realScreenHeight)
//
//    }

func attributedText(withString string: String, boldString: String, font: UIFont) -> NSAttributedString {
  let attributedString = NSMutableAttributedString(string: string,
                                                   attributes: [NSAttributedString.Key.font: font])
  let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
  let range = (string as NSString).range(of: boldString)
  attributedString.addAttributes(boldFontAttribute, range: range)
  attributedString.addAttribute(NSAttributedString.Key.kern, value: 2, range: NSRange(location: 0, length: attributedString.length - 1))
  return attributedString
}


//Mark Extensions

extension String {
  
  var length: Int {
    return self.characters.count
  }
  
  subscript (i: Int) -> String {
    return self[i ..< i + 1]
  }
  
  func substring(fromIndex: Int) -> String {
    return self[min(fromIndex, length) ..< length]
  }
  
  func substring(toIndex: Int) -> String {
    return self[0 ..< max(0, toIndex)]
  }
  
  subscript (r: Range<Int>) -> String {
    let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                        upper: min(length, max(0, r.upperBound))))
    let start = index(startIndex, offsetBy: range.lowerBound)
    let end = index(start, offsetBy: range.upperBound - range.lowerBound)
    return String(self[start ..< end])
  }
}

extension UIView {
  func roundedCorners(top: Bool, cornerRadius: CGFloat, corner: UIRectCorner? = nil){
    var corners:UIRectCorner = (top ? [.topLeft , .topRight] : [.bottomRight , .bottomLeft])
    if corner != nil {
      corners = corner!
    }
    let maskPAth1 = UIBezierPath(roundedRect: self.bounds,
                                 byRoundingCorners: corners,
                                 cornerRadii:CGSize(width:cornerRadius, height:cornerRadius))
    let maskLayer1 = CAShapeLayer()
    maskLayer1.frame = self.bounds
    maskLayer1.path = maskPAth1.cgPath
    self.layer.mask = maskLayer1
  }
}

extension UILabel {
  func addCharacterSpacing() {
    if let labelText = text, labelText.count > 0 {
      let attributedString = NSMutableAttributedString(string: labelText)
      attributedString.addAttribute(NSAttributedString.Key.kern, value: 1.15, range: NSRange(location: 0, length: attributedString.length - 1))
      attributedText = attributedString
    }
  }
  
  func addDoubleCharacterSpacing() {
    if let labelText = text, labelText.count > 0 {
      let attributedString = NSMutableAttributedString(string: labelText)
      attributedString.addAttribute(NSAttributedString.Key.kern, value: 2, range: NSRange(location: 0, length: attributedString.length - 1))
      attributedText = attributedString
    }
  }
  
  //    func addLineSpacing() {
  //        if let labelText = text, labelText.count > 0 {
  //            let attributedString = NSMutableAttributedString(string: labelText)
  //            attributedString.addAttribute(NSAttributedStringKey.kern, value: 2, range: NSRange(location: 0, length: attributedString.length - 1))
  //            attributedText = attributedString
  //            var style = NSMutableParagraphStyle()
  //            style.lineSpacing = 100
  //            attributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: style, range: NSRange(location: 0, length: attributedString.length - 1))
  //
  //        }
  //    }
}

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
}

extension Date {
  /// Returns the amount of years from another date
  func years(from date: Date) -> Int {
    return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
  }
  /// Returns the amount of months from another date
  func months(from date: Date) -> Int {
    return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
  }
  /// Returns the amount of weeks from another date
  func weeks(from date: Date) -> Int {
    return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
  }
  /// Returns the amount of days from another date
  func days(from date: Date) -> Int {
    return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
  }
  /// Returns the amount of hours from another date
  func hours(from date: Date) -> Int {
    return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
  }
  /// Returns the amount of minutes from another date
  func minutes(from date: Date) -> Int {
    return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
  }
  /// Returns the amount of seconds from another date
  func seconds(from date: Date) -> Int {
    return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
  }
  /// Returns the a custom time interval description from another date
  func offset(from date: Date) -> String {
    if years(from: date)   > 0 { return "\(years(from: date))y"   }
    if months(from: date)  > 0 { return "\(months(from: date))M"  }
    if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
    if days(from: date)    > 0 { return "\(days(from: date))d"    }
    if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
    if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
    if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
    return ""
  }
}

extension PHAsset {
  
  func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
    if self.mediaType == .image {
      let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
      options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
        return true
      }
      self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
        completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
      })
    } else if self.mediaType == .video {
      let options: PHVideoRequestOptions = PHVideoRequestOptions()
      options.version = .original
      PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
        if let urlAsset = asset as? AVURLAsset {
          let localVideoUrl: URL = urlAsset.url as URL
          completionHandler(localVideoUrl)
        } else {
          completionHandler(nil)
        }
      })
    }
  }
}

extension Int {
  var kFormatted: String {
    if (self / 1000) > 0 {
      let numberK = Int(self / 1000)
      return "\(numberK)K"
    }
    return "\(self)"
  }
}

extension UIView {
  
  func fadeIn(duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
    UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
      self.alpha = 1.0
    }, completion: completion)  }
  
  func fadeOut(duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
    UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
      self.alpha = 0.0
    }, completion: completion)
  }
}

extension Int {
  
  var ordinal: String {
    var suffix: String
    let ones: Int = self % 10
    let tens: Int = (self/10) % 10
    if tens == 1 {
      suffix = "th"
    } else if ones == 1 {
      suffix = "st"
    } else if ones == 2 {
      suffix = "nd"
    } else if ones == 3 {
      suffix = "rd"
    } else {
      suffix = "th"
    }
    return "\(self)\(suffix)"
  }
  
}

//func getContactsArray(completionHandler :  @escaping ([[String]]) -> ()) {
//    getContacts { contacts in
//        if contacts.count > 0 {
//            completionHandler(retrieveContactsFunction(contacts))
//        }
//    }
//}


//func uploadContacts(completionHandler : @escaping (Bool) -> ()) {
//    getContacts { contacts in
//        if contacts.count > 0 {
//            uploadContactsFunction( { didCompleteSuccesfully in
//                completionHandler(didCompleteSuccesfully)
//            }, contacts)
//        } else {
//            completionHandler(false)
//        }
//    }
//}

//let retrieveContactsFunction : ([CNContact]) -> ([[String]]) = { (contacts) in
//    var contactsMap : [String : String] = [:]
//    var unprocessedContactPhoneNumbers : [String] = []
//    var fullContacts : [[String]] = []
//    var i = 0
//    for contact in contacts {
//        if contact.phoneNumbers.first?.value.stringValue != nil {
//            i += 1
//            contactsMap[(contact.phoneNumbers.first?.value.stringValue)!] = contact.givenName +  " " + contact.familyName
//            unprocessedContactPhoneNumbers.append((contact.phoneNumbers.first?.value.stringValue)!)
//
//        }
//    }
//    let phoneNumberKit = PhoneNumberKit()
//    let contactPhoneNumbers = phoneNumberKit.parse(unprocessedContactPhoneNumbers)
//    for contactPhoneNumber in contactPhoneNumbers {
//        fullContacts.append([contactsMap[contactPhoneNumber.numberString]!, String(contactPhoneNumber.countryCode) + String(contactPhoneNumber.nationalNumber)])
//    }
//    print(fullContacts.count)
//    return fullContacts
//
//}

//let uploadContactsFunction : (@escaping (Bool) -> (), [CNContact]) -> () = { (completionHandler, contacts) in
//    DispatchQueue.global(qos: .background).async {
//        var contactsMap : [String : String] = [:]
//        var unprocessedContactPhoneNumbers : [String] = []
//        var fullContacts : [[String]] = []
//        var i = 0
//        for contact in contacts {
//            if contact.phoneNumbers.first?.value.stringValue != nil {
//                i += 1
//                contactsMap[(contact.phoneNumbers.first?.value.stringValue)!] = contact.givenName +  " " + contact.familyName
//                unprocessedContactPhoneNumbers.append((contact.phoneNumbers.first?.value.stringValue)!)
//
//            }
//        }
//        let phoneNumberKit = PhoneNumberKit()
//        let contactPhoneNumbers = phoneNumberKit.parse(unprocessedContactPhoneNumbers)
//        for contactPhoneNumber in contactPhoneNumbers {
//            fullContacts.append([contactsMap[contactPhoneNumber.numberString]!, String(contactPhoneNumber.countryCode) + String(contactPhoneNumber.nationalNumber)])
//        }
//        print(fullContacts.count)
//        NetworkingManager().uploadContactsList(contactsList: fullContacts) { (didCompleteSuccessfully, forbiddenContacts) in
//            if didCompleteSuccessfully {
//                completionHandler(true)
//            } else {
//                completionHandler(false)
//            }
//        }
//    }
//}
//
//func getContacts(_ completion:  @escaping ([CNContact]) -> ()) {
//
//    let contactsStore = CNContactStore()
//    let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
//
//    if CNContactStore.authorizationStatus(for: CNEntityType.contacts)  == .authorized {
//
//        //Authorization granted by user for this app.
//        var contactsArray = [CNContact]()
//
//        let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
//
//        do {
//            try contactsStore.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
//                //Ordering contacts based on alphabets in firstname
//                if hasValidPhoneNumber(contact: contact) {
//                    contactsArray.append(contact)
//                }
//
//            })
//            completion(contactsArray)
//        }
//            //Catching exception as enumerateContactsWithFetchRequest can throw errors
//        catch let error as NSError {
//            print(error.localizedDescription)
//            completion(contactsArray)
//        }
//
//    }
//}

func hasValidPhoneNumber(contact: CNContact) -> Bool {
  for phoneNumber in  contact.phoneNumbers {
    if phoneNumberIsValid(phoneNumber: phoneNumber.value.stringValue) {
      return true
    }
  }
  return false
}

func phoneNumberIsValid(phoneNumber: String) -> Bool {
  do {
    let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
    let matches = detector.matches(in: phoneNumber, options: [], range: NSMakeRange(0, phoneNumber.count))
    if let res = matches.first {
      return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == phoneNumber.count
    } else {
      return false
    }
  } catch {
    return false
  }
}

func allowedContactKeys() -> [CNKeyDescriptor]{
  //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
  return [CNContactNamePrefixKey as CNKeyDescriptor,
          CNContactGivenNameKey as CNKeyDescriptor,
          CNContactFamilyNameKey as CNKeyDescriptor,
          CNContactOrganizationNameKey as CNKeyDescriptor,
          CNContactBirthdayKey as CNKeyDescriptor,
          CNContactImageDataKey as CNKeyDescriptor,
          CNContactThumbnailImageDataKey as CNKeyDescriptor,
          CNContactImageDataAvailableKey as CNKeyDescriptor,
          CNContactPhoneNumbersKey as CNKeyDescriptor,
          CNContactEmailAddressesKey as CNKeyDescriptor,
  ]
}

extension NSLayoutConstraint {
  /**
   Change multiplier constraint
   
   - parameter multiplier: CGFloat
   - returns: NSLayoutConstraint
   */
  func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
    
    NSLayoutConstraint.deactivate([self])
    
    let newConstraint = NSLayoutConstraint(
      item: firstItem,
      attribute: firstAttribute,
      relatedBy: relation,
      toItem: secondItem,
      attribute: secondAttribute,
      multiplier: multiplier,
      constant: constant)
    
    newConstraint.priority = priority
    newConstraint.shouldBeArchived = self.shouldBeArchived
    newConstraint.identifier = self.identifier
    
    NSLayoutConstraint.activate([newConstraint])
    return newConstraint
  }
}

extension UINavigationController {
  func getPreviousViewController() -> UIViewController? {
    let count = viewControllers.count
    guard count > 1 else { return nil }
    return viewControllers[count - 2]
  }
}

public extension UIDevice {
  
  static let modelName: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
      #if os(iOS)
      switch identifier {
      case "iPod5,1":                                 return "iPod Touch 5"
      case "iPod7,1":                                 return "iPod Touch 6"
      case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
      case "iPhone4,1":                               return "iPhone 4s"
      case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
      case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
      case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
      case "iPhone7,2":                               return "iPhone 6"
      case "iPhone7,1":                               return "iPhone 6 Plus"
      case "iPhone8,1":                               return "iPhone 6s"
      case "iPhone8,2":                               return "iPhone 6s Plus"
      case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
      case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
      case "iPhone8,4":                               return "iPhone SE"
      case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
      case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
      case "iPhone10,3", "iPhone10,6":                return "iPhone X"
      case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
      case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
      case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
      case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
      case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
      case "iPad6,11", "iPad6,12":                    return "iPad 5"
      case "iPad7,5", "iPad7,6":                      return "iPad 6"
      case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
      case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
      case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
      case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
      case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
      case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
      case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
      case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
      case "AppleTV5,3":                              return "Apple TV"
      case "AppleTV6,2":                              return "Apple TV 4K"
      case "AudioAccessory1,1":                       return "HomePod"
      case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
      default:                                        return identifier
      }
      #elseif os(tvOS)
      switch identifier {
      case "AppleTV5,3": return "Apple TV 4"
      case "AppleTV6,2": return "Apple TV 4K"
      case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
      default: return identifier
      }
      #endif
    }
    
    return mapToDevice(identifier: identifier)
  }()
  
}


let badWordsList = ["2g1c",
                    "2 girls 1 cup",
                    "acrotomophilia",
                    "anal",
                    "anilingus",
                    "anus",
                    "arsehole",
                    "ass",
                    "asshole",
                    "assmunch",
                    "auto erotic",
                    "autoerotic",
                    "babeland",
                    "baby batter",
                    "ball gag",
                    "ball gravy",
                    "ball kicking",
                    "ball licking",
                    "ball sack",
                    "ball sucking",
                    "bangbros",
                    "bareback",
                    "barely legal",
                    "barenaked",
                    "bastardo",
                    "bastinado",
                    "bbw",
                    "bdsm",
                    "beaver cleaver",
                    "beaver lips",
                    "bestiality",
                    "bi curious",
                    "big black",
                    "big breasts",
                    "big knockers",
                    "big tits",
                    "bimbos",
                    "birdlock",
                    "bitch",
                    "black cock",
                    "blonde action",
                    "blonde on blonde action",
                    "blow j",
                    "blow your l",
                    "blue waffle",
                    "blumpkin",
                    "bollocks",
                    "bondage",
                    "boner",
                    "boob",
                    "boobs",
                    "booty call",
                    "brown showers",
                    "brunette action",
                    "bukkake",
                    "bulldyke",
                    "bullet vibe",
                    "bung hole",
                    "bunghole",
                    "busty",
                    "butt",
                    "buttcheeks",
                    "butthole",
                    "camel toe",
                    "camgirl",
                    "camslut",
                    "camwhore",
                    "carpet muncher",
                    "carpetmuncher",
                    "chocolate rosebuds",
                    "circlejerk",
                    "cleveland steamer",
                    "clit",
                    "clitoris",
                    "clover clamps",
                    "clusterfuck",
                    "cock",
                    "cocks",
                    "coprolagnia",
                    "coprophilia",
                    "cornhole",
                    "cum",
                    "cumming",
                    "cunnilingus",
                    "cunt",
                    "darkie",
                    "date rape",
                    "daterape",
                    "deep throat",
                    "deepthroat",
                    "dick",
                    "dildo",
                    "dirty pillows",
                    "dirty sanchez",
                    "dog style",
                    "doggie style",
                    "doggiestyle",
                    "doggy style",
                    "doggystyle",
                    "dolcett",
                    "domination",
                    "dominatrix",
                    "dommes",
                    "donkey punch",
                    "double dong",
                    "double penetration",
                    "dp action",
                    "eat my ass",
                    "ecchi",
                    "ejaculation",
                    "erotic",
                    "erotism",
                    "escort",
                    "ethical slut",
                    "eunuch",
                    "faggot",
                    "fecal",
                    "felch",
                    "fellatio",
                    "feltch",
                    "female squirting",
                    "femdom",
                    "figging",
                    "fingering",
                    "fisting",
                    "foot fetish",
                    "footjob",
                    "frotting",
                    "fuck",
                    "fucker",
                    "fucking",
                    "fuck buttons",
                    "fudge packer",
                    "fudgepacker",
                    "futanari",
                    "g-spot",
                    "gang bang",
                    "gay sex",
                    "genitals",
                    "giant cock",
                    "girl on",
                    "girl on top",
                    "girls gone wild",
                    "goatcx",
                    "goatse",
                    "gokkun",
                    "golden shower",
                    "goo girl",
                    "goodpoop",
                    "goregasm",
                    "grope",
                    "group sex",
                    "guro",
                    "hand job",
                    "handjob",
                    "hard core",
                    "hardcore",
                    "hentai",
                    "homoerotic",
                    "honkey",
                    "hooker",
                    "hot chick",
                    "how to kill",
                    "how to murder",
                    "huge fat",
                    "humping",
                    "incest",
                    "intercourse",
                    "jack off",
                    "jail bait",
                    "jailbait",
                    "jerk off",
                    "jigaboo",
                    "jiggaboo",
                    "jiggerboo",
                    "jizz",
                    "juggs",
                    "kike",
                    "kinbaku",
                    "kinkster",
                    "kinky",
                    "knobbing",
                    "leather restraint",
                    "leather straight jacket",
                    "lemon party",
                    "lolita",
                    "lovemaking",
                    "make me come",
                    "male squirting",
                    "masturbate",
                    "menage a trois",
                    "milf",
                    "missionary position",
                    "motherfucker",
                    "mound of venus",
                    "mr hands",
                    "muff diver",
                    "muffdiving",
                    "nambla",
                    "nawashi",
                    "negro",
                    "neonazi",
                    "nig nog",
                    "nigga",
                    "nigger",
                    "nimphomania",
                    "nipple",
                    "nipples",
                    "nsfw images",
                    "nude",
                    "nudity",
                    "nympho",
                    "nymphomania",
                    "octopussy",
                    "omorashi",
                    "one cup two girls",
                    "one guy one jar",
                    "orgasm",
                    "orgy",
                    "paedophile",
                    "panties",
                    "panty",
                    "pedobear",
                    "pedophile",
                    "pegging",
                    "penis",
                    "phone sex",
                    "piece of shit",
                    "piss pig",
                    "pissing",
                    "pisspig",
                    "playboy",
                    "pleasure chest",
                    "pole smoker",
                    "ponyplay",
                    "poof",
                    "poop chute",
                    "poopchute",
                    "porn",
                    "porno",
                    "pornography",
                    "prince albert piercing",
                    "pthc",
                    "pubes",
                    "pussy",
                    "queaf",
                    "raghead",
                    "raging boner",
                    "rape",
                    "raping",
                    "rapist",
                    "rectum",
                    "reverse cowgirl",
                    "rimjob",
                    "rimming",
                    "rosy palm",
                    "rosy palm and her 5 sisters",
                    "rusty trombone",
                    "s&m",
                    "sadism",
                    "scat",
                    "schlong",
                    "scissoring",
                    "semen",
                    "sex",
                    "sexo",
                    "sexy",
                    "shaved beaver",
                    "shaved pussy",
                    "shemale",
                    "shibari",
                    "shit",
                    "shitcock",
                    "shitty",
                    "shota",
                    "shrimping",
                    "slanteye",
                    "slut",
                    "smut",
                    "snatch",
                    "snowballing",
                    "sodomize",
                    "sodomy",
                    "spic",
                    "spooge",
                    "spread legs",
                    "strap on",
                    "strapon",
                    "strappado",
                    "strip club",
                    "style doggy",
                    "suck",
                    "sucks",
                    "suicide girls",
                    "sultry women",
                    "swastika",
                    "swinger",
                    "tainted love",
                    "taste my",
                    "tea bagging",
                    "threesome",
                    "throating",
                    "tied up",
                    "tight white",
                    "tit",
                    "tits",
                    "titties",
                    "titty",
                    "tongue in a",
                    "topless",
                    "tosser",
                    "towelhead",
                    "tranny",
                    "tribadism",
                    "tub girl",
                    "tubgirl",
                    "tushy",
                    "twat",
                    "twink",
                    "twinkie",
                    "two girls one cup",
                    "undressing",
                    "upskirt",
                    "urethra play",
                    "urophilia",
                    "vagina",
                    "venus mound",
                    "vibrator",
                    "violet blue",
                    "violet wand",
                    "vorarephilia",
                    "voyeur",
                    "vulva",
                    "wank",
                    "wet dream",
                    "wetback",
                    "white power",
                    "women rapping",
                    "wrapping men",
                    "wrinkled starfish",
                    "xx",
                    "xxx",
                    "yaoi",
                    "yellow showers",
                    "yiffy",
                    "zoophilia",
                    "fat",
                    "ugly",
                    "faggots",
                    "faggot",
                    "wtf",
                    "fack"]

extension String {
  
  func slice(from: String, to: String) -> String? {
    
    return (range(of: from)?.upperBound).flatMap { substringFrom in
      (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
        String(self[substringFrom..<substringTo])
      }
    }
  }
}

extension UITextField{
  
  func addDoneButtonToKeyboard(myAction:Selector?){
    let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
    doneToolbar.barStyle = UIBarStyle.default
    
    let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
    let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: myAction)
    
    var items = [UIBarButtonItem]()
    items.append(flexSpace)
    items.append(done)
    
    doneToolbar.items = items
    doneToolbar.sizeToFit()
    
    self.inputAccessoryView = doneToolbar
  }
}
