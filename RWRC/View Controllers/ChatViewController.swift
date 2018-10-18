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
import Photos
import Firebase
import MessageKit
import FirebaseFirestore
import Kingfisher
import FirebaseStorage
import UserNotifications
import FirebaseMessaging
import PKHUD
import StoreKit

final class ChatViewController: MessagesViewController, UIGestureRecognizerDelegate {
  
  private var isSendingPhoto = false {
    didSet {
      DispatchQueue.main.async {
        self.messageInputBar.leftStackViewItems.forEach { item in
          item.isEnabled = !self.isSendingPhoto
        }
      }
    }
  }
  
  private let db = Firestore.firestore()
  private var reference: CollectionReference?
  private let storage = Storage.storage().reference()
  
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  private var channel: Channel
  private var oldInputView : UIView?
  private var oldInputType : Message.InputType?
  private var isWaitingToSendClassificationRequest = false
  
  //Custom picker view vars
  let customPickerView = UIPickerView()
  private var customPicerViewType : CustomPickerViewTypes = .dayOfTheWeek
  
  let daysOfTheWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "None"]
  let weightDenominations = ["Pounds", "Kilograms"]
  let yesOrNoArr = ["Yes", "No"]
  let confirmCaloriesArr = ["Yes", "No", "Enter different amount"]
  let heightDenominations = ["Feet", "Meters"]
  let genderDenominations = ["Female", "Male", "Non-Binary"]
  var selectedDays : [Int] = []
  var selectedTypeDenominationForPickerView = 0
  
  enum CustomPickerViewTypes {
    case weight
    case dayOfTheWeek
    case yesOrNo
    case height
    case gender
    case confirmCalories
  }
  
  deinit {
    messageListener?.remove()
  }
  
  init(channel: Channel) {
    self.channel = channel
    super.init(nibName: nil, bundle: nil)
    
    title = channel.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if UserDataManager.sharedInstance.didPurchaseIndiPro == true {
      if UserDataManager.sharedInstance.configs.aggressiveReviewRequest && UserDataManager.sharedInstance.hasAskedForReview == false {
        let alertController = UIAlertController(title: "Could you give Indi 5 stars?", message: "It really helps! ☺️", preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
          SKStoreReviewController.requestReview()
          self.messageInputBar.inputTextView.becomeFirstResponder()
          UserDataManager.sharedInstance.hasAskedForReview = true
        })
        
        alertController.addAction(okButton)
        self.present(alertController, animated: true)
        
      } else {
        SKStoreReviewController.requestReview()
        messageInputBar.inputTextView.becomeFirstResponder()
      }
    }
    
    switch environment {
    case .logInAsUser:
      let alert = UIAlertController(title: "Log in as user",
                                    message: "Enter user Id",
                                    preferredStyle: .alert)
      
      alert.addTextField { (textField) in
        textField.text = ""
      }
      
      let action = UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
        let textField = alert!.textFields![0]
        if textField.text != "" && textField.text != "0" {
          UserDataManager.sharedInstance.userId = textField.text
        }
      })
      
      alert.addAction(action)
      
      present(alert, animated: true, completion: nil)
    case .development, .production, .production2:
      break
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let id = channel.id else {
      navigationController?.popViewController(animated: true)
      return
    }
    
    reference = db.collection(["channels", id, "thread"].joined(separator: "/"))
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
    
    navigationItem.largeTitleDisplayMode = .never
    
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    
    //    let cameraItem = InputBarButtonItem(type: .system) // 1
    //    cameraItem.tintColor = .primary
    //    cameraItem.image = #imageLiteral(resourceName: "camera")
    //    cameraItem.addTarget(
    //      self,
    //      action: #selector(cameraButtonPressed), // 2
    //      for: .primaryActionTriggered
    //    )
    //    cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
    
    let indiProItem = UIBarButtonItem()
    if UserDataManager.sharedInstance.didPurchaseIndiPro == true {
      indiProItem.title = ""
    } else {
      let a = UserDataManager.sharedInstance.configs
      indiProItem.title = UserDataManager.sharedInstance.configs.activateIndiButtonName
    }
    
    indiProItem.action = #selector(indiProButtonPressed)
    navigationItem.rightBarButtonItem = indiProItem
    
        let profileItem = UIBarButtonItem()
        profileItem.image = #imageLiteral(resourceName: "camera")
        profileItem.action = #selector(profileButtonPressed)
        navigationItem.leftBarButtonItem = profileItem
    
    messageInputBar.leftStackView.alignment = .center
    // messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
    // messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false) // 3
    
    self.messagesCollectionView.messageCellDelegate = self
    
    oldInputView = messageInputBar.inputTextView.inputView
    
    customPickerView.delegate = self
    let pickerViewTap = UITapGestureRecognizer(target: self, action: #selector(pickerTapped))
    pickerViewTap.delegate = self
    customPickerView.addGestureRecognizer(pickerViewTap)
    
    self.registerForPushNotifications()
    
    if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
      layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
    }
    UserDataManager.sharedInstance.getConfigData()
  }
  
  // MARK: - Actions
  
  @objc private func indiProButtonPressed() {
    let storyboard = UIStoryboard(name: "Purchases", bundle: nil)
    var indiProVC = storyboard.instantiateViewController(withIdentifier: Identifiers.indiProVC)
    self.navigationController?.pushViewController(indiProVC, animated: true)
  }
  
  @objc private func profileButtonPressed() {
    let storyboard = UIStoryboard(name: "Journal", bundle: nil)
    var journalVC = storyboard.instantiateViewController(withIdentifier: "FoodJournalVC")
    self.present(journalVC, animated: true, completion: nil)
  }
  
  //  @objc private func cameraButtonPressed() {
  //    let picker = UIImagePickerController()
  //    picker.delegate = self
  //
  //    if UIImagePickerController.isSourceTypeAvailable(.camera) {
  //      picker.sourceType = .camera
  //    } else {
  //      picker.sourceType = .photoLibrary
  //    }
  //
  //    present(picker, animated: true, completion: nil)
  //  }
  
  
  func didPurchasePro() {
    navigationItem.rightBarButtonItem?.title = ""
    HUD.flash(HUDContentType.labeledSuccess(title: "Success!", subtitle: "  Indi has been activated!  "), delay: 2.5)
  }
  
  // MARK: - Helpers
  
  private func save(_ message: Message) {
    reference?.addDocument(data: message.representation) { error in
      if let e = error {
        print("Error sending message: \(e.localizedDescription)")
        return
      }
      self.messagesCollectionView.scrollToBottom()
      if !self.isWaitingToSendClassificationRequest {
        self.isWaitingToSendClassificationRequest = true
        self.requestMessageClassificationIfNecessary(previousTextInputContent:  self.messageInputBar.inputTextView.text)
      }
    }
  }
  
  private func requestMessageClassificationIfNecessary(previousTextInputContent: String) {
    let _ = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false, block: { (_) in
      if self.messageInputBar.inputTextView.text == previousTextInputContent {
        print("requesting classification")
        self.requestMessageClassification()
      } else {
        print("delaying classification request")
        self.requestMessageClassificationIfNecessary(previousTextInputContent:  self.messageInputBar.inputTextView.text)
      }
    })
  }
  
  private func requestMessageClassification() {
    NetworkingManager().requestMessageClassification { (didCompleteSuccessfully) in
      if !didCompleteSuccessfully {
        self.requestMessageClassification()
      } else {
        self.isWaitingToSendClassificationRequest = false
      }
    }
  }
  
  private func insertNewMessage(_ message: Message) {
    guard !messages.contains(message) else {
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.index(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
    
    if isLatestMessage && !isFromCurrentSender(message: message) {
      adaptKeboardToInputType(message)
    }
    
  }
  
  private func updateMessageImage(_ message: Message) {
    guard messages.contains(message) else {
      return
    }
    
    messages[messages.index(of: message)!].image = message.image
    messagesCollectionView.reloadData()
    
  }
  
  private func adaptKeboardToInputType(_ message: Message) {
    
    switch message.inputType {
    case .age:
      let datePickerView:UIDatePicker = UIDatePicker()
      datePickerView.datePickerMode = .date
      datePickerView.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
      messageInputBar.inputTextView.inputView = datePickerView
    case .weight:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .weight
      customPickerView.reloadAllComponents()
    case .yesOrNo:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .yesOrNo
      customPickerView.reloadAllComponents()
      messageInputBar.inputTextView.text = "Yes"
    case .confirmCalories:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .confirmCalories
      customPickerView.reloadAllComponents()
      messageInputBar.inputTextView.text = "Yes"
    case .gender:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .gender
      customPickerView.reloadAllComponents()
    case .daysOfTheWeek:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .dayOfTheWeek
      customPickerView.reloadAllComponents()
    case .height:
      messageInputBar.inputTextView.inputView = customPickerView
      customPicerViewType = .height
      customPickerView.reloadAllComponents()
    case .number:
      messageInputBar.inputTextView.inputView = oldInputView
      self.messageInputBar.inputTextView.keyboardType = .numberPad
    case .text:
      messageInputBar.inputTextView.inputView = oldInputView
      self.messageInputBar.inputTextView.keyboardType = .default
    }
    if oldInputType != message.inputType {
      messageInputBar.inputTextView.resignFirstResponder()
      messageInputBar.inputTextView.becomeFirstResponder()
      oldInputType = message.inputType
    }
  }
  
  
  @objc private func datePickerValueChanged(sender:UIDatePicker) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none
    messageInputBar.inputTextView.text = dateFormatter.string(from: sender.date)
    
  }
  
  @objc private func weightPickerValueChanged(sender:UIPickerView) {
    
    print("things are happening")
    
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard var message = Message(document: change.document) else {
      return
    }
    
    switch change.type {
    case .added:
      if let url = message.downloadURL {
        message.image = #imageLiteral(resourceName: "Empty")
        self.insertNewMessage(message)
        //        downloadImage(at: url) { [weak self] image in
        //          guard let `self` = self else {
        //            return
        //          }
        //          guard let image = image else {
        //            return
        //          }
        //
        //          message.image = image
        //         // self.updateMessageImage(message)
        //        }
      } else {
        insertNewMessage(message)
      }
      
    default:
      break
    }
  }
  
  private func uploadImage(_ image: UIImage, to channel: Channel, completion: @escaping (URL?) -> Void) {
    guard let channelID = channel.id else {
      completion(nil)
      return
    }
    
    guard let scaledImage = image.scaledToSafeUploadSize, let data = scaledImage.jpegData(compressionQuality: 0.4) else {
      completion(nil)
      return
    }
    
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    
    let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
    storage.child(channelID).child(imageName).putData(data, metadata: metadata) { (meta, error) in
      self.storage.child(channelID).child(imageName).downloadURL(completion: { (url, e) in
        completion(url)
      })
    }
    //    storage.child(channelID).child(imageName).putData(data, metadata: metadata) { meta, error in
    //      completion(meta.dow)
    //    }
  }
  
  private func sendPhoto(_ image: UIImage) {
    isSendingPhoto = true
    
    uploadImage(image, to: channel) { [weak self] url in
      guard let `self` = self else {
        return
      }
      self.isSendingPhoto = false
      
      guard let url = url else {
        return
      }
      
      var message = Message(image: image)
      message.downloadURL = url
      
      self.save(message)
      self.messagesCollectionView.scrollToBottom()
    }
  }
  
  private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
    let ref = Storage.storage().reference(forURL: url.absoluteString)
    let megaByte = Int64(1 * 1024 * 1024)
    
    ref.getData(maxSize: megaByte) { data, error in
      guard let imageData = data else {
        completion(nil)
        return
      }
      
      completion(UIImage(data: imageData))
    }
  }
  
  func registerForPushNotifications() {
    if UserDataManager.sharedInstance.hasReceivedPushNotificationsRequest != true {
      if #available(iOS 10.0, *) {
        let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { didAuthorize,_ in
            if didAuthorize {
            }
        })
      }
      
      let application = UIApplication.shared
      application.registerForRemoteNotifications()
      UserDataManager.sharedInstance.hasReceivedPushNotificationsRequest = true
    }
  }
  
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? ColorPalette.indiBlue : .incomingMessage
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
    return false
  }
  
  func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
    return [.url]
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    
    
    switch message.kind {
    case .photo:
      let configurationClosure = { (containerView: UIImageView) in
        let imageMask = UIImageView()
        imageMask.image = MessageStyle.bubble.image
        imageMask.frame = containerView.bounds
        containerView.mask = imageMask
        containerView.contentMode = .scaleAspectFill
        
        containerView.kf.indicatorType = .activity
        let message = self.messages[indexPath.section]
        guard
          let url = message.downloadURL
          else {
            print("Could not convert message into a readable Message format")
            return
        }
        
        print("Setting image to \(url.absoluteString)")
        containerView.kf.setImage(with: url)
      }
      return .custom(configurationClosure)
      
    default:
      let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
      return .bubbleTail(corner, .curved)
    }
  }
  
  
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    if message.sender.id == "Indi" {
      avatarView.image = UIImage(named: "indiTransparent")
      avatarView.backgroundColor = .white
    } else {
      avatarView.image = UIImage(named: "userAvatar.jpg")
      avatarView.backgroundColor = .white
    }
  }
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .zero
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 0, height: 0)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    return 0
  }
  
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  
  func currentSender() -> Sender {
    return Sender(id: UserDataManager.sharedInstance.userId!, displayName: "user")
  }
  
  func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
  }
  
  func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    return nil
    //    let name = message.sender.displayName
    //    return NSAttributedString(
    //      string: name,
    //      attributes: [
    //        .font: UIFont.preferredFont(forTextStyle: .caption1),
    //        .foregroundColor: UIColor(white: 0.3, alpha: 1)
    //      ]
    //    )
  }
  
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: MessageInputBarDelegate {
  
  
  
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    let message = Message(content: text)
    AnalyticsManager().recordEvent(eventName: AnalyticsManager.AnalyticsEvents.sentMessage)
    save(message)
    inputBar.inputTextView.text = ""
  }
  
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    //    picker.dismiss(animated: true, completion: nil)
    //
    //    if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset { // 1
    //      let size = CGSize(width: 500, height: 500)
    //      PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil) { result, info in
    //        guard let image = result else {
    //          return
    //        }
    //
    //        self.sendPhoto(image)
    //      }
    //    } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage { // 2
    //      sendPhoto(image)
    //    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
  
}

extension ChatViewController: MessageCellDelegate {
  func didTapMessage(in cell: MessageCollectionViewCell) {
    print(messagesCollectionView.indexPath(for: cell)?.section)
  }
  
  func didSelectURL(_ url: URL) {
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}

extension ChatViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    switch customPicerViewType {
    case .weight:
      return 2
    case .dayOfTheWeek:
      return 1
    case .gender:
      return 1
    case .height:
      return 2
    case .yesOrNo:
      return 1
    case .confirmCalories:
      return 1
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    
    switch customPicerViewType {
    case .weight:
      if component == 1 {
        return 2
      } else {
        if selectedTypeDenominationForPickerView == 0 {
          return 600
        } else {
          return 400
        }
      }
    case .height:
      if component == 1 {
        return 2
      } else {
        if selectedTypeDenominationForPickerView == 0 {
          return 55
        } else {
          return 100
        }
      }
    case .dayOfTheWeek:
      return 8
    case .gender:
      return 3
    case .yesOrNo:
      return 2
    case .confirmCalories:
      return 3
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    switch customPicerViewType {
    case .weight:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          return "\(row + 50) lbs"
        } else {
          return "\(row + 25) kgs"
        }
      } else {
        return weightDenominations[row]
      }
    case .height:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          return "\((row + 36)/12)' \(row % 12)''"
        } else {
          return "\(row + 100) Centimeters"
        }
      } else {
        return heightDenominations[row]
      }
    case .dayOfTheWeek:
      return daysOfTheWeek[row]
    case .gender:
      return genderDenominations[row]
    case .yesOrNo:
      return yesOrNoArr[row]
    case .confirmCalories:
      return confirmCaloriesArr[row]
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    switch customPicerViewType {
    case .weight:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          messageInputBar.inputTextView.text = "I weigh \(row + 50) lbs"
        } else {
          messageInputBar.inputTextView.text = "I weigh \(row + 25) kgs"
        }
      } else {
        selectedTypeDenominationForPickerView = row
        pickerView.reloadComponent(0)
        messageInputBar.inputTextView.text = ""
      }
    case .height:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          messageInputBar.inputTextView.text = "I'm \((row + 36)/12) Feet, \(row % 12) Inches tall"
        } else {
          messageInputBar.inputTextView.text = "I'm \((Double(row) + 100.0)/100.0) Meters tall"
        }
      } else {
        selectedTypeDenominationForPickerView = row
        pickerView.reloadComponent(0)
        messageInputBar.inputTextView.text = ""
      }
    case .gender:
      messageInputBar.inputTextView.text = genderDenominations[row]
    case .yesOrNo:
      messageInputBar.inputTextView.text = yesOrNoArr[row]
    case .confirmCalories:
      messageInputBar.inputTextView.text = confirmCaloriesArr[row]
    case .dayOfTheWeek:
      if selectedDays.contains(row) {
        selectedDays = selectedDays.filter { $0 != row }
      } else {
        selectedDays.append(row)
      }
      
      selectedDays.sort { $0 < $1 }
      
      var remindMeOnString = ""
      if selectedDays.contains(7) {
        remindMeOnString = "Don't remind me"
        selectedDays = []
      } else if selectedDays.count > 0 {
        remindMeOnString = "Remind me on"
        for day in selectedDays {
          remindMeOnString = remindMeOnString + " " + daysOfTheWeek[day] + ","
        }
        remindMeOnString = remindMeOnString.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal , range: remindMeOnString.range(of: ",", options: NSString.CompareOptions.backwards))
        remindMeOnString = remindMeOnString.replacingOccurrences(of: ",", with: " and", options: NSString.CompareOptions.literal , range: remindMeOnString.range(of: ",", options: NSString.CompareOptions.backwards))
      }
      pickerView.reloadAllComponents()
      customPickerView.selectRow(row, inComponent: 0, animated: false)
      messageInputBar.inputTextView.text = remindMeOnString
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    
    let pickerLabel = UILabel()
    pickerLabel.textAlignment = NSTextAlignment.center
    pickerLabel.textColor = UIColor.black
    pickerLabel.font = UIFont.systemFont(ofSize: 20)
    
    switch customPicerViewType {
    case .weight:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          pickerLabel.text = "\(row + 50) lbs"
        } else {
          pickerLabel.text = "\(row + 25) kgs"
        }
      } else {
        pickerLabel.text = weightDenominations[row]
      }
    case .height:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          pickerLabel.text = "\((row + 36)/12)' \(row % 12)''"
        } else {
          pickerLabel.text = "\((Double(row) + 100.0)/100.0) Meters"
        }
      } else {
        pickerLabel.text = heightDenominations[row]
      }
    case .gender:
      pickerLabel.text = genderDenominations[row]
    case .yesOrNo:
      pickerLabel.text = yesOrNoArr[row]
    case .confirmCalories:
      pickerLabel.text = confirmCaloriesArr[row]
    case .dayOfTheWeek:
      pickerLabel.text = daysOfTheWeek[row]
      if selectedDays.contains(row) {
        pickerLabel.font = UIFont.boldSystemFont(ofSize: 20)
      }
    }
    
    return pickerLabel
    
  }
  
  
  @objc func pickerTapped(tapRecognizer: UITapGestureRecognizer) {
    
    switch customPicerViewType{
    case .dayOfTheWeek, .yesOrNo, .confirmCalories:
      if tapRecognizer.state == .ended {
        let rowHeight = self.customPickerView.rowSize(forComponent: 0).height
        let selectedRowFrame = self.customPickerView.bounds.insetBy(dx: 0, dy: (self.customPickerView.frame.height - rowHeight) / 2)
        let userTappedOnSelectedRow = selectedRowFrame.contains(tapRecognizer.location(in: self.customPickerView))
        if userTappedOnSelectedRow {
          let selectedRow = self.customPickerView.selectedRow(inComponent: 0)
          pickerView(customPickerView, didSelectRow: selectedRow, inComponent: 0)
        }
      }
    default:
      break
    }
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  
}

