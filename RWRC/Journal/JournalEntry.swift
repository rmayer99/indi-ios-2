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
  var id: Int
  var createdAt: Date
  
  init(name: String, totalCalories: Int, quantityDescription: String, id: Int, createdAt: Date) {
    self.name = name
    self.totalCalories = totalCalories
    self.quantityDescription = quantityDescription
    self.id = id
    self.createdAt = createdAt
  }
  
}
