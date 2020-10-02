//
//  TealiumHelper.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift
import TealiumBraze

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "braze-tag"
    static let environment = "dev"
}

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
        profile: TealiumConfiguration.profile,
        environment: TealiumConfiguration.environment)

    var tealium: Tealium?
    
    static var universalData = [String: Any]()
    
    // JSON Remote Command
    let brazeRemoteCommand = BrazeRemoteCommand(type: .remote(url: "https://tags.tiqcdn.com/dle/tealiummobile/demo/braze.json"))

    private init() {
        config.shouldUseRemotePublishSettings = false
        config.batchingEnabled = false
        config.remoteAPIEnabled = true
        config.logLevel = .info
        config.collectors = [Collectors.Lifecycle]
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.RemoteCommands]
        
        config.addRemoteCommand(brazeRemoteCommand)
        
        tealium = Tealium(config: config)
    }


    public func start() {
        _ = TealiumHelper.shared
    }

    class func trackView(title: String, data: [String: Any]?) {
        let tealiumView = TealiumView(title, dataLayer: data)
        TealiumHelper.shared.tealium?.track(tealiumView)
    }

    class func trackEvent(title: String, data: [String: Any]?) {
        if let data = data {
            universalData = universalData.merging(data) { _, new in new }
        }
        let tealiumEvent = TealiumEvent(title, dataLayer: universalData)
        TealiumHelper.shared.tealium?.track(tealiumEvent)
    }

}
