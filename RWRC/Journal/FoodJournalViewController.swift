//
//  FoodJournalViewController.swift
//  RWRC
//
//  Created by Ruben Mayer on 10/17/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit
import PKHUD

class FoodJournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  var dayIndex = 0
   //var journalEntriesT = [JournalEntry(name: "Apple", totalCalories: 80, quantityDescription: "One cup", id: 1), JournalEntry(name: "Banana", totalCalories: 90, quantityDescription: "Three slices", id: 2), JournalEntry(name: "Starbucks Sandwhich", totalCalories: 533, quantityDescription: "one sandwhich", id: 3), JournalEntry(name: "Apple", totalCalories: 80, quantityDescription: "One cup", id: 4)]
  var journalEntries : [JournalEntry] = []
  @IBOutlet weak var emptyStateTextLabel: UILabel!
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var tableViewFrame: UIView!
  @IBOutlet weak var quickAddButton: UIButton!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var totalCaloriesLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    quickAddButton.layer.cornerRadius = 20
    self.navigationController?.isNavigationBarHidden = true
    
    let gradient = CAGradientLayer()
    gradient.frame = tableViewFrame.bounds
    gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
    gradient.locations = [0, 0.05, 0.95, 1]
    tableViewFrame.layer.mask = gradient
    emptyStateView.layer.cornerRadius = 20
    if journalEntries.count == 0 {
      emptyStateView.isHidden = false
    } else {
      emptyStateView.isHidden = true
    }
    
    if UserDataManager.sharedInstance.didPurchaseIndiPro != true {
      quickAddButton.isHidden = true
    }
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 220))
    downloadEntriesForDay(dayIndex: 0)
  }
  
  @IBAction func didPressQuickAddButton(_ sender: Any) {
    journalEntries.insert(JournalEntry(name: "Quick Add", totalCalories: 0, quantityDescription: "", id: Int.random(in: -9999999999 ..< -1), createdAt: Date()), at: 0)
    reloadTableView()
    let indexPath = IndexPath(item: 0, section: 0)
    self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    let cell = tableView.cellForRow(at: indexPath)! as! FoodJournalTableViewCell
    cell.caloriesLabel.text = ""
    cell.caloriesLabel.becomeFirstResponder()
  }
  @IBAction func didPressRightButton(_ sender: Any) {
    dayIndex += 1
    updateDataGivenDayIndex(index: dayIndex)
  }
  
  @IBAction func didPressLeftButton(_ sender: Any) {
    dayIndex -= 1
    updateDataGivenDayIndex(index: dayIndex)
  }
  
  func updateDataGivenDayIndex(index: Int) {
    let today = Date()
    let relevantDay = Calendar.current.date(byAdding: .day, value: index, to: today)
    let df = DateFormatter()
    df.setLocalizedDateFormatFromTemplate("MMM dd")
    let date = df.string(from: relevantDay!)
    if dayIndex <= 0 {
      downloadEntriesForDay(dayIndex: dayIndex)
    }
    if dayIndex <= -2 {
      dateLabel.text = date
      quickAddButton.isHidden = true
    } else if dayIndex == -1 {
      dateLabel.text = "Yesterday"
      quickAddButton.isHidden = true
    } else if dayIndex == 0 {
      dateLabel.text = "Today"
      if UserDataManager.sharedInstance.didPurchaseIndiPro == true {
        quickAddButton.isHidden = false
      }
    } else if dayIndex == 1 {
      dateLabel.text = "Tomorrow"
      journalEntries = []
      quickAddButton.isHidden = true
    } else if dayIndex >= 2 {
      dateLabel.text = date
      journalEntries = []
      quickAddButton.isHidden = true
    }
    
    reloadTableView()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return journalEntries.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "FoodJournalTableViewCell", for: indexPath) as! FoodJournalTableViewCell
    let journalEntry = journalEntries[indexPath.item]
    cell.background.layer.cornerRadius = 8
    cell.caloriesLabel.text = String(journalEntry.totalCalories)
    cell.foodNameLabel.text = journalEntry.name
    if journalEntry.quantityDescription.length > 0 {
      cell.foodQuantityLabel.text = "(" + journalEntry.quantityDescription + ")"
    } else {
      cell.foodQuantityLabel.text = ""
    }
    cell.foodJournalVC = self
    cell.id = journalEntry.id
    return cell
  }
  
  
  @IBAction func didPressCloseButton(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  func deleteEntry(id: Int) {
    let entry = journalEntries.filter {$0.id == id}[0]
    let alert = UIAlertController(title: "", message: "Delete \"" + entry.name + "\"?", preferredStyle: .actionSheet)
    
    alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
      self.sendDeleteEntry(entryId: id)
    }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler:{ (UIAlertAction)in
      print("User click Edit button")
    }))
    self.present(alert, animated: true, completion: nil)
  }
  
  func updateEntryCalories(id: Int, calories: Int) {
    if id < 0 {
      sendQuickAddEntry(calories: calories, id: id)
    } else {
      updateCaloriesValueForEntry(entryId: id, newValue: calories)
    }
  }
  
  func scrollToCellWithId(id: Int) {
    let index = journalEntries.index{$0.id == id}!
    tableView.scrollToRow(at: IndexPath(item: index, section: 0), at: UITableView.ScrollPosition.top, animated: true)
  }
  
  func reloadTableView() {
    if journalEntries.count == 0 {
      emptyStateView.isHidden = false
      if dayIndex < 0 {
        emptyStateTextLabel.text = "You didn't input any\nfood for this day ☹️"
      } else if dayIndex == 0 {
        emptyStateTextLabel.text = "To start logging food\ntell Indi what you ate 🍎"
      } else {
        emptyStateTextLabel.text = "This day hasn't started yet!"
      }
    } else {
      emptyStateView.isHidden = true
    }
    var totalCalories = 0
    for entry in journalEntries {
      totalCalories += entry.totalCalories
    }
    totalCaloriesLabel.text = "Total Calories: " + String(totalCalories)
    tableView.reloadData()
  }
  
  func updateCaloriesValueForEntry(entryId: Int, newValue: Int) {
    NetworkingManager().editCaloriesEntry(entryId: entryId, newValue: newValue)  { (didCompleteSuccessfully) in
      HUD.hide()
      if !didCompleteSuccessfully {
        HUD.flash(HUDContentType.labeledError(title: "Error Updating Calories", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
      } else {
        if let index = self.journalEntries.index(where: {$0.id == entryId}) {
          self.journalEntries[index].totalCalories = newValue
          self.reloadTableView()
        }
      }
    }
  }
  
  func sendQuickAddEntry(calories: Int, id: Int) {
    NetworkingManager().quickAddCaloriesEntry(caloriesValue: calories) { (didCompleteSuccessfully, newId) in
      HUD.hide()
      if !didCompleteSuccessfully {
        HUD.flash(HUDContentType.labeledError(title: "Error Adding Calories", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
      } else {
        if let index = self.journalEntries.index(where: {$0.id == id}) {
          self.journalEntries[index].totalCalories = calories
          self.journalEntries[index].id = newId
          self.reloadTableView()
        }
      }
    }
  }
  
  func downloadEntriesForDay(dayIndex: Int) {
    HUD.show(.progress)
    NetworkingManager().getCaloriesEntriesForDateRange(dateIndex: dayIndex) { (didCompleteSuccessfully, journalEntries) in
      HUD.hide()
      if didCompleteSuccessfully {
        self.journalEntries = journalEntries
        self.reloadTableView()
      } else {
        HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
      }
    }
    
  }
  
  func sendDeleteEntry(entryId: Int) {
    NetworkingManager().deleteCaloriesEntry(entryId: entryId) { (didCompleteSuccessfully) in
      HUD.hide()
      if !didCompleteSuccessfully {
        HUD.flash(HUDContentType.labeledError(title: "Error Deleting Entry", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
      } else {
        self.journalEntries = self.journalEntries.filter {$0.id != entryId}
        self.reloadTableView()
      }
    }
  }
  
}
