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

import Firebase
import MessageKit
import FirebaseFirestore

struct Message: MessageType {
  
  
  let id: String?
  let content: String
  let sentDate: Date
  let sender: Sender
  var inputType : InputType = .text
  
  enum InputType {
    case text
    case weight
    case age
    case yesOrNo
    case gender
    case number
    case daysOfTheWeek
    case height
    case confirmCalories
    case weightGoal
    case lifestyleType
  }
  
  var kind: MessageKind {
    if let image = image {
      return .photo(image)
    } else {
      return .text(content)
    }
  }
  
  var messageId: String {
    return id ?? UUID().uuidString
  }
  
  var image: UIImage? = nil
  var downloadURL: URL? = nil
  
  init(content: String) {
    sender = Sender(id: UserDataManager.sharedInstance.userId!, displayName: "user")
    self.content = content
    sentDate = Date()
    id = nil
  }
  
  init(image: UIImage) {
    sender = Sender(id: UserDataManager.sharedInstance.userId!, displayName: "user")
    self.image = image
    content = ""
    sentDate = Date()
    id = nil
  }
  
  init?(document: QueryDocumentSnapshot) {
    let data = document.data()
    
    guard let sentDate = data["created"] as? Timestamp else {
      return nil
    }
    guard let senderID = data["senderID"] as? String else {
      return nil
    }
    guard let senderName = data["senderName"] as? String else {
      return nil
    }
    id = document.documentID
    self.sentDate = sentDate.dateValue()
    sender = Sender(id: senderID, displayName: senderName)
    
    if let content = data["content"] as? String {
      self.content = content
      downloadURL = nil
    } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
      downloadURL = url
      content = ""
    } else {
      return nil
    }
    let inputTypeDescription = data["inputType"] as? String ?? "text"
    print(data["inputType"] as? String)
    self.inputType = processInputType(inputType: inputTypeDescription)
    
    

    if senderID == "Indi" && data["newState"] as? Int != nil &&  UserDataManager.sharedInstance.currentStateSendDate < Int(self.sentDate.timeIntervalSince1970) {
      UserDataManager.sharedInstance.currentState = data["newState"] as! Int
      UserDataManager.sharedInstance.currentStateSendDate = Int(self.sentDate.timeIntervalSince1970)
    }
    
    if let activateDiscount = data["activateDiscount"] as? Bool {
      UserDataManager.sharedInstance.discountActivated = activateDiscount
    }
  }
  
  private func processInputType(inputType : String) -> InputType {
    if inputType == "WEIGHT" {
      return .weight
    } else if inputType == "AGE" {
      return .age
    } else if inputType == "YESORNO" {
      return .yesOrNo
    } else if inputType == "CONFIRMCALORIES" {
      AnalyticsManager().recordEvent(eventName: AnalyticsManager.AnalyticsEvents.queriedCalories)
      return .confirmCalories
    } else if inputType == "GENDER" {
      return .gender
    } else if inputType == "NUMBER" {
      return .number
    } else if inputType == "DAY" {
      return .daysOfTheWeek
    } else if inputType == "HEIGHT" {
      return .height
    } else if inputType == "WEIGHT_GOAL" {
      return .weightGoal
    } else if inputType == "LIFESTYLE_TYPE" {
      return .lifestyleType
    } else {
      return .text
    }
  }
  
}

extension Message: DatabaseRepresentation {
  
  var representation: [String : Any] {
    var rep: [String : Any] = [
      "created": sentDate,
      "senderID": sender.id,
      "senderName": sender.displayName,
      "inputType" : "userGenerated",
      "wasProcessed" : false
    ]
    
    if let url = downloadURL {
      rep["url"] = url.absoluteString
    } else {
      rep["content"] = content
    }
    
    return rep
  }
  
}

extension Message: Comparable {
  
  static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Message, rhs: Message) -> Bool {
    return lhs.sentDate < rhs.sentDate
  }
  
}
