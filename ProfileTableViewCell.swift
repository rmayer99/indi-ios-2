//
//  ProfileTableViewCell.swift
//  RWRC
//
//  Created by Ruben Mayer on 11/21/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell, UITextFieldDelegate {
  
  enum InputType {
    case text
    case date
    case lifestyleType
    case weightGoal
    case weight
    case height
  }
  
  var parentVC : ProfileTableViewController!
  var inputType : InputType = .height
  let weightDenominations = ["Pounds", "Kilograms"]
  let heightDenominations = ["Feet", "Meters"]
  let lifestyleTypes = ["Sedentary", "Slightly Active", "Very Active", "Hardcore"]
  let weightGoalsInLbs = ["Lose 2 lbs", "Lose 1 lb", "Stay the same", "Gain 1 lb", "Gain 2 lbs"]
  let weightGoalsInKgs = ["Lose 1 Kilo", "Lose 0.5 Kilos", "Stay the same", "Gain 0.5 Kilos", "Gain 1 Kilo"]
  var selectedTypeDenominationForPickerView = 0
  
  @IBOutlet weak var textField: UITextField!
  override func awakeFromNib() {
    super.awakeFromNib()
    textField.delegate = self
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    switch inputType {
    case .text:
      parentVC.profileUpdates["name"] = textField.text as AnyObject
    default:
      break
    }
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    
    switch inputType {
    case .text:
      break
    case .date:
      let picker = UIDatePicker()
      picker.datePickerMode = .date
      picker.addTarget(self, action: #selector(updateDateField(sender:)), for: .valueChanged)
      textField.inputView = picker
    default:
      let picker = UIPickerView()
      picker.delegate = self
      textField.inputView = picker
    }
    
    
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.endEditing(true)
    return true
  }
  
  @objc func updateDateField(sender: UIDatePicker) {
    self.textField.text = formatDateForDisplay(date: sender.date)
    parentVC.profileUpdates["date_of_birth"] = stringFromDate(date: sender.date)

  }
}

extension ProfileTableViewCell: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    switch inputType {
    case .weight:
      return 2
    case .height:
      return 2
    case .weightGoal:
      return 2
    case .lifestyleType:
      return 1
    case .date, .text:
      return 1
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    
    switch inputType {
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
    case .weightGoal:
      if component == 1 {
        return 2
      } else {
        return 5
      }
    case .lifestyleType:
      return 4
    case .date, .text:
      return 1
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    switch inputType {
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
    case .lifestyleType:
      return lifestyleTypes[row]
    case .weightGoal:
      if selectedTypeDenominationForPickerView == 0 {
        return weightGoalsInLbs[row]
      } else {
        return weightGoalsInKgs[row]
      }
    case .text, .date:
      return "Error"
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    switch inputType {
    case .weight:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          textField.text = "\(row + 50) lbs"
          parentVC.profileUpdates["weight"] = Double(row + 50) * 0.454 as AnyObject
          UserDataManager.sharedInstance.preferredWeightDenomination = "pounds"
        } else {
          textField.text = "\(row + 25) kgs"
          parentVC.profileUpdates["weight"] = Double(row + 25) as AnyObject
          UserDataManager.sharedInstance.preferredWeightDenomination = "kilos"
        }
      } else {
        selectedTypeDenominationForPickerView = row
        pickerView.reloadComponent(0)
      }
    case .height:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          textField.text = "\((row + 36)/12)'\(row % 12)"
          parentVC.profileUpdates["height"] = Double(row + 36) * 0.0254 as AnyObject
          UserDataManager.sharedInstance.preferredHeightDenomination = "feet"
        } else {
          textField.text = "\((Double(row) + 100.0)/100.0) M"
          parentVC.profileUpdates["height"] = Double(row + 100)/100.0 as AnyObject
          UserDataManager.sharedInstance.preferredHeightDenomination = "meters"
        }
      } else {
        selectedTypeDenominationForPickerView = row
        pickerView.reloadComponent(0)
      }
    case .weightGoal:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          UserDataManager.sharedInstance.preferredWeightDenomination = "pounds"
          if row == 2 {
            textField.text = weightGoalsInLbs[row]
            parentVC.profileUpdates["weekly_weight_goal"] = Double(row - 2) * 0.5 as AnyObject
          } else {
            textField.text = weightGoalsInLbs[row]
            parentVC.profileUpdates["weekly_weight_goal"] = Double(row - 2) * 0.5 as AnyObject
          }
        } else {
          UserDataManager.sharedInstance.preferredWeightDenomination = "kilos"
          if row == 2 {
            textField.text = weightGoalsInKgs[row]
            parentVC.profileUpdates["weekly_weight_goal"] = Double(row - 2) * 0.5 as AnyObject
          } else {
            textField.text = weightGoalsInKgs[row]
            parentVC.profileUpdates["weekly_weight_goal"] = Double(row - 2) * 0.5 as AnyObject
          }
        }
      } else {
        selectedTypeDenominationForPickerView = row
        pickerView.reloadComponent(0)
      }
    case .lifestyleType:
      textField.text = lifestyleTypes[row]
      parentVC.profileUpdates["lifestyle_type"] = row as AnyObject
    case .text, .date:
      break
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    
    let pickerLabel = UILabel()
    pickerLabel.textAlignment = NSTextAlignment.center
    pickerLabel.textColor = UIColor.black
    pickerLabel.font = UIFont.systemFont(ofSize: 20)
    
    switch inputType {
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
    case .weightGoal:
      if component == 0 {
        if selectedTypeDenominationForPickerView == 0 {
          pickerLabel.text = weightGoalsInLbs[row]
        } else {
          pickerLabel.text = weightGoalsInKgs[row]
        }
      } else {
        pickerLabel.text = weightDenominations[row]
      }
    case .lifestyleType:
      pickerLabel.text = lifestyleTypes[row]
    case .text, .date:
      pickerLabel.text = "Error"
      
    }
    return pickerLabel
  }
}
