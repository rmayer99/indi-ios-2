//
//  FoodJournalTableViewCell.swift
//  RWRC
//
//  Created by Ruben Mayer on 10/17/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit

class FoodJournalTableViewCell: UITableViewCell, UITextFieldDelegate {
  
  
  
  @IBOutlet weak var caloriesLabel: UITextField!
  @IBOutlet weak var background: UIView!
  @IBOutlet weak var foodNameLabel: UILabel!
  @IBOutlet weak var foodQuantityLabel: UILabel!
  weak var foodJournalVC : FoodJournalViewController!
  var id: Int!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    caloriesLabel.delegate = self
    self.caloriesLabel.addDoneButtonToKeyboard(myAction: #selector(self.caloriesLabel.resignFirstResponder))
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  @IBAction func didPressDeleteButton(_ sender: Any) {
    foodJournalVC.deleteEntry(id: id)
  }
  
  
  @IBAction func didTapCell(_ sender: Any) {
    self.caloriesLabel.becomeFirstResponder()
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    foodJournalVC.updateEntryCalories(id: id, calories: Int(textField.text ?? "0") ?? 0)
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    foodJournalVC.scrollToCellWithId(id: id)
  }
  
}
