//
//  BrazeRemoteCommandTests.swift
//  TealiumBrazeTests
//
//  Created by Enrico Zannini on 08/11/22.
//  Copyright © 2022 Jonathan Wong. All rights reserved.
//

import XCTest
@testable import TealiumBraze
import TealiumCore

class BrazeRemoteCommandTests: XCTestCase {

    func testConvertToBool() {
        let braze = BrazeRemoteCommand()
        XCTAssertTrue(braze.convertToBool("true")!)
        XCTAssertTrue(braze.convertToBool(true)!)
        XCTAssertTrue(braze.convertToBool(1)!)
        XCTAssertFalse(braze.convertToBool(0)!)
        XCTAssertFalse(braze.convertToBool("false")!)
        XCTAssertFalse(braze.convertToBool(false)!)
        XCTAssertNil(braze.convertToBool("wrong string"))
    }

    func testCreateConfigWithoutEnvironment() {
        let braze = BrazeRemoteCommand()
        let config: [String: Any] = [BrazeConstants.Keys.apiKey:""]
        XCTAssertNil(braze.createConfig(payload: config), "Custom endpoint should be required")
    }

    func testCreateConfigWithEndpoint() {
        let braze = BrazeRemoteCommand()
        let config: [String: Any] = [BrazeConstants.Keys.apiKey: "", BrazeConstants.Keys.customEndpoint: ""]
        let brazeConfig = braze.createConfig(payload: config)
        XCTAssertNotNil(brazeConfig, "A configuration is always created when API key and CustomEndpoint are provided")
        XCTAssertEqual(brazeConfig?.api.sdkFlavor, .tealium, "Flavour tealium should always be present in the config")
    }
}
