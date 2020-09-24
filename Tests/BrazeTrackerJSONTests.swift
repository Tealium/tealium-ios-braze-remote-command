//
//  BrazeTrackerJSONTests.swift
//  TealiumBrazeTests
//
//  Created by Christina S on 9/24/20.
//  Copyright © 2020 Tealium. All rights reserved.
//

import XCTest
@testable import TealiumBraze
#if COCOAPODS
#else
    import TealiumRemoteCommands
#endif

class BrazeTrackerJSONTests: XCTestCase {

    let brazeTracker = MockBrazeTracker()
    var brazeCommand: BrazeRemoteCommand!

    override func setUp() {
        brazeCommand = BrazeRemoteCommand(brazeTracker: brazeTracker)
    }

    override func tearDown() {

    }

    func testInitializeIsNotCalledWithoutApiKey() {
        let expect = expectation(description: "test initialize called without api key")
        let payload = ["command_name": "initialize"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.initializeBrazeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    // HERE
    func testInitializeCalledWithApiKey() {
        let expect = expectation(description: "test initialize called with api key")
        let payload = ["command_name": "initialize", "api_key": "test123"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.initializeBrazeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testInitializeWithAppboyOptions() {
        let expect = expectation(description: "test initialize with appboy options")
        let payload: [String: Any] = [
            "command_name": "initialize",
            "api_key": "abc123",
            "disable_location": "false",
            "enable_geofences": "true",
            "trigger_interval_seconds": 5.0,
            "flush_interval": 12.0,
            "request_processing_policy": 1,
            "device_options": 10,
            "push_story_identifier": "test.push.story.id",
            "enable_advertiser_tracking": true,
            "enable_deep_link_handling": true
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKEnableAutomaticLocationCollectionKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKEnableGeofencesKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKMinimumTriggerTimeIntervalKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKFlushIntervalOptionKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKRequestProcessingPolicyOptionKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKDeviceWhitelistKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKPushStoryAppGroupKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKIDFADelegateKey"]!)
            XCTAssertEqual(1, brazeTracker.appBoyOptionsCount["ABKURLDelegateKey"]!)
        }
        wait(for: [expect], timeout: 2.0)
    }
    
    func testChangeUserIdentifierCalledSuccess() {
        let expect = expectation(description: "test change user identifier called success")
        let userIdentifier = "tealium-ios-test-user"
        let payload = ["command_name": "initialize,useridentifier", "user_id": userIdentifier]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.changeUserCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogSingleLocation() {
        let expect = expectation(description: "test log single location")
        let payload: [String: Any] = [
            "command_name": "initialize",
            "api_key": "abc123",
            "disable_location": "false",
            "enable_geofences": "true"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.logSingleLocationCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetLastKnownLocationWithAltitudeAndVerticalAccuracy() {
        let expect = expectation(description: "test last known location with altitude and vertical accuracy")
        let payload: [String: Any] = [
            "command_name": "setlastknownlocation",
            "disable_locaiton": "false", "location_longitude": 123.123, "location_latitude": 12.123, "location_horizontal_accuracy": 12.0,
            "location_altitude": 12.0,
            "location_vertical_accuracy": 12.0
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.setLastKnownLocationWithAltitudeVerticalAccuracyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetLastKnownLocationNoAltitudeAndVerticalAccuracy() {
        let expect = expectation(description: "test last known location without altitude and vertical accuracy")
        let payload: [String: Any] = [
            "command_name": "setlastknownlocation",
            "disable_locaiton": "false", "location_longitude": 123.123, "location_latitude": 12.123, "location_horizontal_accuracy": 12.0
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.setLastKnownLocationNoAltitudeVerticalAccuracyCallCount)
        }
        wait(for: [expect], timeout: 5.0)
    }

    func testChangeUserIdentifierNotCalled_userIdentifierKeyMissing() {
        let expect = expectation(description: "test user identifier")
        let payload = ["command_name": "initialize,useridentifier"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.changeUserCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUserAliasNotCalled_keysMissing() {
        let expect = expectation(description: "test user alias not called")
        let payload: [String: Any] = ["command_name": "initialize,useralias",
            "user_alias": "test_alias"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.addAliasCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUserAliasNotCalledSuccess() {
        let expect = expectation(description: "test user alias called")
        let payload: [String: Any] = ["command_name": "initialize,useralias",
            "user_alias": "test_alias",
            "alias_label": "alias_label"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.addAliasCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogCustomEventSuccess() {
        let expect = expectation(description: "test log event success")
        let payload = ["command_name": "initialize,lOGcustomEvent","event_name": "test_event"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.logCustomEventCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogCustomEventNotCalled_logCustomEventNameMissing() {
        let expect = expectation(description: "test log event with event name missing")
        let payload = ["command_name": "initialize,lOGcustomEvent"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logCustomEventCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogCustomEventSuccess_propertiesMissing() {
        let expect = expectation(description: "test log event without properties")
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
            "event_name": "test_event",
            "properties_key_misnamed": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"]]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.logCustomEventCallCount)
            XCTAssertEqual(0, brazeTracker.logCustomEventWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogCustomEventWithProperties() {
        let expect = expectation(description: "test log event with properties")
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
            "event_name": "test_event",
            "event_properties": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"]]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logCustomEventCallCount)
            XCTAssertEqual(1, brazeTracker.logCustomEventWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUserAttributesSet() {
        let expect = expectation(description: "test user attribute set")
        let dateString = Date().iso8601String
        let payload = [
            "command_name": "initialize,useridentifier,userAttribute",
            "first_name": "first_name_test",
            "last_name": "last_name_test",
            "email": "email_test",
            "date_of_birth": "\(dateString)",
            "country": "country_test",
            "language": "language_test",
            "home_city": "home_city_test",
            "phone": "phone_test",
            "avatar_image_url": "avatar_image_url_test",
            "gender": "male"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(10, brazeTracker.setUserAttributeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUserAttributesSetOnlyCallsAppboyUserAttributeKeys() {
        let expect = expectation(description: "test user attribute set")
        let payload = [
            "command_name": "initialize,useridentifier,userAttribute",
            "first_name": "first_name_test",
            "last_name": "last_name_test",
            "email": "email_test",
            "country": "country_test",
            "language": "language_test",
            "home_city": "home_city_test",
            "phone": "phone_test",
            "avatar_image_url": "avatar_image_url_test",
            "not_a_user_attribute_key": "123",
            "not_a_user_attribute_key2": "456"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(8, brazeTracker.setUserAttributeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testFacebookUserSet() {
        let expect = expectation(description: "test facebook user set")
        let payload: [String: Any] = ["command_name": "initialize,facebookuser",
            "facebook_id": [
                "user_info": [:],
                "friends_count": 100,
                "likes": ["apple", "orange"]
            ]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.facebookUserCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testTwitterUserSet() {
        let expect = expectation(description: "test twitter user set")
        let payload: [String: Any] = ["command_name": "initialize,twitteruser",
            "twitter_user": [
                "user_info": [:],
                "friends_count": 100,
                "likes": []
            ]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.twitterUserCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testCustomAttributesSet() {
        let expect = expectation(description: "test custom attribute set")
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
            "set_custom_attribute": [
                "boolkey": false,
                "intkey": 1,
                "doublekey": 2.0,
                "stringkey": "test_string"]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(4, brazeTracker.setCustomAttributeWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testCustomAttributesNotCalled_keyMissing() {
        let expect = expectation(description: "test custom attribute set")
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
            "boolkey": false,
            "intkey": 1,
            "doublekey": 2.0,
            "stringkey": "test_string"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUnsetCustomAttributesNotCalled_keyMissing() {
        let expect = expectation(description: "test custom attribute unset")
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testUnsetCustomAttributesNotCalledSuccess() {
        let expect = expectation(description: "test custom attribute unset")
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute",
            "unset_custom_attribute": "attribute_key"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testIncrementCustomAttributeSuccess() {
        let expect = expectation(description: "test increment custom attribute")
        let payload: [String: Any] = ["command_name": "initialize,incrementcustomattribute",
            "increment_custom_attribute": ["key1": 1,
                "key2": 2]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(2, brazeTracker.incrementCustomUserAttributeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testCustomArrayAttributeSet() {
        let expect = expectation(description: "test custom array attribute set")
        let payload: [String: Any] = ["command_name": "initialize,setcustomarrayattribute",
            "set_custom_array_attribute": [
                "array_key1": ["value1", "value2", "value3"],
                "array_key2": ["value1", "value2", "value3"],
                "array_key3": ["value1", "value2", "value3"],
            ]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(3, brazeTracker.setCustomAttributeWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testAddToCustomAttributeArraySuccess() {
        let expect = expectation(description: "test add to custom array attribute")
        let payload: [String: Any] = ["command_name": "initialize,appendcustomarrayattribute",
            "append_custom_array_attribute": [
                "array_key1": "value1",
                "array_key2": "value2",
                "array_key3": "value3"
            ]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(3, brazeTracker.addToCustomAttributeArrayWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testRemoveCustomAttributeArraySuccess() {
        let expect = expectation(description: "test remove custom array attribute")
        let payload: [String: Any] = ["command_name": "initialize,removecustomarrayattribute",
            "remove_custom_array_attribute": [
                "array_key1": "value1",
                "array_key2": "value2",
                "array_key3": "value3"
            ]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(3, brazeTracker.removeFromCustomAttributeArrayWithKeyCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetEmailNotificationSubscriptionTypeSuccess() {
        let expect = expectation(description: "test set email notification subscription type")
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
            "email_notification": "optedIn"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetEmailNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let expect = expectation(description: "test set email notification subscription type")
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
            "email_notification": "UN subscribed"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetPushNotificationSubscriptionTypeSuccess() {
        let expect = expectation(description: "test set push notification subscription type")
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
            "push_notification": "subscribed"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.setPushNotificationSubscriptionTypeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testSetPushNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let expect = expectation(description: "test set push notification subscription type")
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
            "email_notification": "SUBscribed"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseNotCalled_productIdentifierMissing() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "order_currency": "USD",
            "product_unit_price": 12.34
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseNotCalled_currencyMissing() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": "123",
            "product_unit_price": 12.34
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseNotCalled_priceMissing() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": "123",
            "order_currency": "USD"
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseSuccess() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.logPurchaseCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseWithQuantitySuccess() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "quantity": [5]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            XCTAssertEqual(1, brazeTracker.logPurchaseWithQuantityCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseWithPropertiesSuccess() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "purchase_properties": ["item1": 123]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
            XCTAssertEqual(1, brazeTracker.logPurchaseWithPropertiesCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testLogPurchaseWithPropertiesWithQuantitySuccess() {
        let expect = expectation(description: "test log purchase")
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": [12.34, 1.99],
            "quantity": [1, 2],
            "purchase_properties": ["item1": 123]
        ]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
            XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
            XCTAssertEqual(1, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testDisableSDK() {
        let expect = expectation(description: "sdk is disabled")
        let payload: [String: Any] = ["command_name": "enablesdk",
            "enable_sdk": false]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.disableCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testReenableSDK() {
        let expect = expectation(description: "sdk is reenabled")
        let payload: [String: Any] = ["command_name": "enablesdk",
            "enable_sdk": true]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.reEnableCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testWipeData() {
        let expect = expectation(description: "wipe data is called")
        let payload: [String: Any] = ["command_name": "wipedata"]
        if let response = HttpTestHelpers.createRemoteCommandResponse(type: .JSON, commandId: "braze", payload: payload) {
            brazeCommand.completion(response)
            expect.fulfill()
            XCTAssertEqual(1, brazeTracker.wipeDataCallCount)
        }
        wait(for: [expect], timeout: 2.0)
    }
}

