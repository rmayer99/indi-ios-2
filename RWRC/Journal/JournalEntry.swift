//
//  JournalEntry.swift
//  RWRC
//
//  Created by Ruben Mayer on 10/17/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
class JournalEntry {
  var name: String
  var totalCalories: Int
  var quantityDescription: String
  let id: Int
  
  init(name: String, totalCalories: Int, quantityDescription: String, id: Int) {
    self.name = name
    self.totalCalories = totalCalories
    self.quantityDescription = quantityDescription
    self.id = id
  }
  
}
