//
//  TealiumHelper.swift
//  BrazeRemoteCommand
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Jonathan Wong. All rights reserved.
//

import Foundation
import TealiumSwift
import TealiumBraze

class TealiumHelper {
    
    static let shared = TealiumHelper()
    let config = TealiumConfig(account: "tealiummobile",
                               profile: "braze-tag",
                               environment: "qa",
                               datasource: nil)
    
    var tealium: Tealium?
    static var universalData = [String: Any]()
    
    private init() {
        config.logLevel = .verbose
        config.shouldUseRemotePublishSettings = false
        config.batchingEnabled = false
        tealium = Tealium(config: config) { responses in
            guard let remoteCommands = self.tealium?.remoteCommands() else {
                return
            }
            let brazeTracker = BrazeTracker()
            let brazeCommand = BrazeCommand(brazeTracker: brazeTracker)
            let brazeRemoteCommand = brazeCommand.remoteCommand()
            remoteCommands.add(brazeRemoteCommand)
        }
    }
    
    class func start() {
        _ = TealiumHelper.shared
    }
    
    class func track(title: String, data: [String: Any]?) {
        if let data = data {
            universalData = universalData.merging(data) { _, new in new }
        }
        TealiumHelper.shared.tealium?.track(title: title, data: universalData, completion: nil)
    }
}
