//
//  DateConverter.swift
//  RemoteCommandModules
//
//  Created by Jonathan Wong on 1/10/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

class DateConverter {
    
    static let shared = DateConverter()
    
  let iso8601DateFormatter: ISO8601DateFormatter = {
    if #available(iOS 11.0, *) {
      return ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
    } else {
      return ISO8601DateFormatter([.withInternetDateTime])
    }
  }()
}

extension ISO8601DateFormatter {
    
    convenience init(_ formatOptions: Options, timeZone: TimeZone? = nil) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone ?? TimeZone(secondsFromGMT: 0)
    }
}