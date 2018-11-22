//
//  ProfileTableViewController.swift
//  RWRC
//
//  Created by Ruben Mayer on 11/21/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit
import PKHUD

class ProfileTableViewController: UITableViewController {
  
  var profileData : [(String, String, ProfileTableViewCell.InputType)] = [("Name", "", .text), ("Birthday", "", .date), ("Height", "", .height), ("Weight", "", .weight)]
  
  var profileUpdates : [String: Any] = [:]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadProfileData()

    let saveItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.saveProfile))
    self.navigationItem.rightBarButtonItem = saveItem
    
    let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.didPressCancelButton))
    self.navigationItem.leftBarButtonItem = cancelItem
  }
  
  
  func loadProfileData() {
    HUD.show(.progress)
    NetworkingManager().getUserProfile() { (didCompleteSuccessfully, profileData) in
      HUD.hide()
      if didCompleteSuccessfully {
        self.profileData = profileData
        self.tableView.reloadData()
      } else {
        HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
      }
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return profileData.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as! ProfileTableViewCell
    cell.textField.text = profileData[indexPath.section].1
    cell.inputType = profileData[indexPath.section].2
    cell.parentVC = self
    return cell
  }
  
  override func tableView( _ tableView : UITableView,  titleForHeaderInSection section: Int)->String {
    return profileData[section].0.uppercased()
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor.darkGray
    header.textLabel?.font = UIFont.systemFont(ofSize: 12)
  }
  
  @objc func saveProfile() {
    if profileUpdates.count == 0 {
      self.navigationController?.popViewController(animated: true)
    } else {
      HUD.show(.progress)
      NetworkingManager().setUserInfo(isNewUser: false, edittedParams: self.profileUpdates) { (didCompleteSuccessfully) in
        HUD.hide()
        if didCompleteSuccessfully {
          self.navigationController?.popViewController(animated: true)
        } else {
          HUD.flash(HUDContentType.labeledError(title: "Error", subtitle: " Are you connected to the internet? "),  delay: 2, completion: nil)
        }
      }
    }
  }
    
  @objc func didPressCancelButton() {
    if profileUpdates.count == 0 {
      self.navigationController?.popViewController(animated: true)
    } else {
      let alertController = UIAlertController(title: "Discard Changes?", message: "If you go back now, your changes will not be saved.", preferredStyle: .alert)
      
      let discardButton = UIAlertAction(title: "Discard Changes", style: .default, handler: { (action) -> Void in
        self.navigationController?.popViewController(animated: true)
      })
      
      let keepEditingButton = UIAlertAction(title: "Keep Editing", style: .default, handler: { (action) -> Void in
      })
      
      alertController.addAction(discardButton)
      alertController.addAction(keepEditingButton)
      self.present(alertController, animated: true)
    }
  }
  
  
  /*
   // Override to support conditional editing of the table view.
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the specified item to be editable.
   return true
   }
   */
  
  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
   if editingStyle == .delete {
   // Delete the row from the data source
   tableView.deleteRows(at: [indexPath], with: .fade)
   } else if editingStyle == .insert {
   // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }
   }
   */
  
  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
   
   }
   */
  
  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
   // Return false if you do not want the item to be re-orderable.
   return true
   }
   */
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}
