//
//  BrazeExtensionsTests.swift
//  TealiumBrazeTests
//
//  Created by Enrico Zannini on 08/11/22.
//  Copyright © 2022 Jonathan Wong. All rights reserved.
//

import XCTest
import BrazeKit
@testable import TealiumBraze

class BrazeExtensionsTests: XCTestCase {
    func testRequestPolicy() {
        for policy in Braze.Configuration.Api.RequestPolicy.allCases {
            let policyString = "\(policy)"
            XCTAssertEqual(policy, Braze.Configuration.Api.RequestPolicy.from(policyString))
            XCTAssertEqual(policy, Braze.Configuration.Api.RequestPolicy.from(policyString.lowercased()))
            XCTAssertEqual(policy, Braze.Configuration.Api.RequestPolicy.from(policyString.uppercased()))
        }
        XCTAssertNil(Braze.Configuration.Api.RequestPolicy.from("wrong string"))
    }

    func testDeviceProperty() {
        for deviceProperty in Braze.Configuration.DeviceProperty.allCases {
            let property = "\(deviceProperty)"
            XCTAssertEqual(deviceProperty, Braze.Configuration.DeviceProperty.from(property))
            XCTAssertEqual(deviceProperty, Braze.Configuration.DeviceProperty.from(property.lowercased()))
            XCTAssertEqual(deviceProperty, Braze.Configuration.DeviceProperty.from(property.uppercased()))
        }
        XCTAssertNil(Braze.Configuration.DeviceProperty.from("wrong string"))
    }

    func testUserGender() {
        for gender in Braze.User.Gender.allCases {
            let genderString = "\(gender)"
            XCTAssertEqual(gender, Braze.User.Gender.from(genderString))
            XCTAssertEqual(gender, Braze.User.Gender.from(genderString.lowercased()))
            XCTAssertEqual(gender, Braze.User.Gender.from(genderString.uppercased()))
        }
        XCTAssertEqual(.notApplicable, Braze.User.Gender.from("not_applicable"))
        XCTAssertEqual(.preferNotToSay, Braze.User.Gender.from("wrong string"))
    }

    func testSubscriptionState() {
        for subscriptionState in Braze.User.SubscriptionState.allCases {
            let subscription = "\(subscriptionState)"
            XCTAssertEqual(subscriptionState, Braze.User.SubscriptionState.from(subscription))
            XCTAssertEqual(subscriptionState, Braze.User.SubscriptionState.from(subscription.lowercased()))
            XCTAssertEqual(subscriptionState, Braze.User.SubscriptionState.from(subscription.uppercased()))
        }
        XCTAssertNil(Braze.User.SubscriptionState.from("wrong string"))
    }
}
