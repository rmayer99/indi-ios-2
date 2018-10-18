//
//  Constants.swift
//  RWRC
//
//  Created by Ruben Mayer on 8/15/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import Foundation
import UIKit

struct Identifiers {
  static let signupVC = "SignUpVC"
  static let onboardingVC = "OnboardingVC"
  static let indiProVC = "IndiProVC"
}

struct ColorPalette {
  static let mainBlue = UIColor(rgb: 0x3E486E)
  static let mainPurple = UIColor(rgb: 0x66438A)
  static let mainAqua = UIColor(rgb: 0x1B717A)
  static let indiBlue = UIColor(rgb: 0x95D4D1)
}

enum Environment {
  case development
  case production
  case logInAsUser
  case production2
}

let environment : Environment = .development

