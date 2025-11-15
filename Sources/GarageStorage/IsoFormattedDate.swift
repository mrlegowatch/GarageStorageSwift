//
//  IsoFormattedDate.swift
//  GarageStorage
//
//  Created by Brian Arnold on 9/9/19.
//  Copyright © 2015-2024 Wellframe. All rights reserved.
//

import Foundation

extension Date {
    
    static internal let isoFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()
    
    static internal func isoDate(for string: String) -> Date? {
        return Date.isoFormatter.date(from: string)
    }
    
    internal var isoString: String {
        return Date.isoFormatter.string(from: self)
    }
    
}
