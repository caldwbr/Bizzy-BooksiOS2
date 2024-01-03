//
//  SentenceElementProtocol.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 1/2/24.
//

import Foundation
import SwiftUI
protocol SentenceElementProtocol {
    static var defaultTuple: (String?, String) { get }
    static var tuple: (String?, String) { get }
    static var color: Color { get }
    static func reset()
}

struct WhoSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = (nil, "Who ▼")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.whoBlue
    static func reset() {
        tuple = defaultTuple
    }
}

struct PaidSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = ("", "paid")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.black
    static func reset() {
        tuple = defaultTuple
    }
}

struct WhatSE {
    static let defaultTuple: (String?, String) = (nil, "what")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.whatGreen
    static func reset() {
        tuple = defaultTuple
    }
}

struct ToWSE {
    static let defaultTuple: (String?, String) = ("", "to")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.black
    static func reset() {
        tuple = defaultTuple
    }
}

struct WhomSE {
    static let defaultTuple: (String?, String) = (nil, "whom ▼")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.whomPurple
    static func reset() {
        tuple = defaultTuple
    }
}

struct ForWhatSE {
    static let defaultTuple: (String?, String) = ("", "for what")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.black
    static func reset() {
        tuple = defaultTuple
    }
}

struct TaxReasonSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = ("0", "tax reason")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.taxReasonMagenta
    static func reset() {
        tuple = defaultTuple
    }
}

struct PersonalReasonSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = ("0", "personal reason")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.personalReasonMagenta
    static func reset() {
        tuple = defaultTuple
    }
}

struct ProjectSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = (nil, "project ▼")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.projectBlue
    static func reset() {
        tuple = defaultTuple
    }
}

struct ForHSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = ("", "for")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.black
    static func reset() {
        tuple = defaultTuple
    }
}

struct HowManySE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = (nil, "how many")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.darkerGreen
    static func reset() {
        tuple = defaultTuple
    }
}

struct GallonsOfFuelInSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = ("", "gallons of fuel in")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.black
    static func reset() {
        tuple = defaultTuple
    }
}

struct VehicleSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = (nil, "vehicle ▼")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.orange
    static func reset() {
        tuple = defaultTuple
    }
}

struct OdometerSE: SentenceElementProtocol {
    static let defaultTuple: (String?, String) = (nil, "odometer")
    static var tuple: (String?, String) = defaultTuple
    static let color = Color.BizzyColor.grey
    static func reset() {
        tuple = defaultTuple
    }
}

struct Sentences {
    static let oneDefault: [(String?, String)] = [WhoSE.tuple, PaidSE.tuple, WhatSE.tuple, ToWSE.tuple, WhomSE.tuple, ForWhatSE.tuple, TaxReasonSE.tuple, ProjectSE.tuple]
    static let twoDefault: [(String?, String)] = [WhoSE.tuple, PaidSE.tuple, WhatSE.tuple, ToWSE.tuple, WhomSE.tuple, ForWhatSE.tuple, PersonalReasonSE.tuple]
    static let threeDefault: [(String?, String)] = [WhoSE.tuple, PaidSE.tuple, WhatSE.tuple, ToWSE.tuple, WhomSE.tuple, ForHSE.tuple, HowManySE.tuple, GallonsOfFuelInSE.tuple, VehicleSE.tuple, OdometerSE.tuple]
    static var one: [(String?, String)] = oneDefault
    static var two: [(String?, String)] = twoDefault
    static var three: [(String?, String)] = threeDefault
    
    static func clearValues() {
        WhoSE.reset()
        WhatSE.reset()
        WhomSE.reset()
        TaxReasonSE.reset()
        PersonalReasonSE.reset()
        VehicleSE.reset()
        ProjectSE.reset()
        HowManySE.reset()
        VehicleSE.reset()
        OdometerSE.reset()
        one = oneDefault
        two = twoDefault
        three = threeDefault
    }
}
