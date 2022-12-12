//
//  BrazeProcessCommandTests.swift
//  TealiumBrazeTests
//
//  Created by Christina S on 9/24/20.
//  Copyright © 2020 Tealium. All rights reserved.
//

import XCTest
@testable import TealiumBraze
import BrazeKit
#if COCOAPODS
#else
    import TealiumRemoteCommands
#endif

class BrazeProcessCommandTests: XCTestCase {

    let brazeInstance = MockBrazeInstance()
    var brazeCommand: BrazeRemoteCommand!

    override func setUp() {
        brazeCommand = BrazeRemoteCommand(brazeInstance: brazeInstance)
    }

    override func tearDown() {

    }

    func testInitializeIsNotCalledWithoutApiKey() {
        let payload = ["command_name": "initialize"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.initializeBrazeCallCount)
    }

    // HERE
    func testInitializeCalledWithApiKey() {
        let payload = ["command_name": "initialize", "api_key": "test123", "custom_endpoint": "testEndpoint"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.initializeBrazeCallCount)
    }

    func testInitializeWithBrazeConfig() {
        let payload: [String: Any] = [
            "command_name": "initialize",
            "api_key": "abc123",
            "custom_endpoint": "test_endpoint",
            "enable_automatic_location": "true",
            "enable_geofences": "true",
            "enable_automatic_geofences": "true",
            "trigger_interval_seconds": 5.0,
            "flush_interval": 12.0,
            "request_processing_policy": "manual",
            "device_options": ["carrier", "locale", "model"],
            "push_story_identifier": "test.push.story.id",
        ]
        brazeCommand.processRemoteCommand(with: payload)
        let config = brazeInstance.config
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.api.key, (payload["api_key"] as! String))
        XCTAssertEqual(config!.api.endpoint, (payload["custom_endpoint"] as! String))
        XCTAssertEqual(config!.api.flushInterval, payload["flush_interval"] as! Double)
        XCTAssertEqual(config!.api.requestPolicy, Braze.Configuration.Api.RequestPolicy.from((payload["request_processing_policy"] as! String)))
        XCTAssertEqual(config!.devicePropertyAllowList, Set((payload["device_options"] as! [String]).compactMap(Braze.Configuration.DeviceProperty.from(_:))))
        XCTAssertEqual(config!.push.appGroup, (payload["push_story_identifier"] as! String))
        XCTAssertEqual(config!.triggerMinimumTimeInterval, payload["trigger_interval_seconds"] as! Double)
        XCTAssertEqual("\(config!.location.geofencesEnabled)", payload["enable_geofences"] as! String)
        XCTAssertEqual("\(config!.location.automaticGeofenceRequests)", payload["enable_automatic_geofences"] as! String)
        XCTAssertEqual("\(config!.location.automaticLocationCollection)", (payload["enable_automatic_location"] as! String))
    }
    
    func testChangeUserIdentifierCalledSuccess() {
        let userIdentifier = "tealium-ios-test-user"
        let payload = ["command_name": "initialize,useridentifier", "user_id": userIdentifier]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.changeUserCallCount)
    }

    func testSetLastKnownLocationWithAltitudeAndVerticalAccuracy() {
        let payload: [String: Any] = [
            "command_name": "setlastknownlocation",
            "disable_locaiton": "false", "location_longitude": 123.123, "location_latitude": 12.123, "location_horizontal_accuracy": 12.0,
            "location_altitude": 12.0,
            "location_vertical_accuracy": 12.0
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setLastKnownLocationWithAltitudeVerticalAccuracyCallCount)
    }

    func testSetLastKnownLocationNoAltitudeAndVerticalAccuracy() {
        let payload: [String: Any] = [
            "command_name": "setlastknownlocation",
            "disable_locaiton": "false", "location_longitude": 123.123, "location_latitude": 12.123, "location_horizontal_accuracy": 12.0
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setLastKnownLocationNoAltitudeVerticalAccuracyCallCount)
    }

    func testChangeUserIdentifierNotCalled_userIdentifierKeyMissing() {
        let payload = ["command_name": "initialize,useridentifier"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.changeUserCallCount)
    }

    func testUserAliasNotCalled_keysMissing() {
        let payload: [String: Any] = ["command_name": "initialize,useralias",
            "user_alias": "test_alias"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.addAliasCallCount)
    }

    func testUserAliasNotCalledSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,useralias",
            "user_alias": "test_alias",
            "alias_label": "alias_label"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.addAliasCallCount)
    }

    func testLogCustomEventSuccess() {
        let payload = ["command_name": "initialize,lOGcustomEvent","event_name": "test_event"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventCallCount)
    }

    func testLogCustomEventNotCalled_logCustomEventNameMissing() {
        let payload = ["command_name": "initialize,lOGcustomEvent"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventCallCount)
    }

    func testLogCustomEventSuccess_propertiesMissing() {
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
            "event_name": "test_event",
            "properties_key_misnamed": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"]]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventCallCount)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogCustomEventWithProperties() {
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
            "event_name": "test_event",
            "event_properties": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"]]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventCallCount)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testUserAttributesSet() {
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
            "gender": "male"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(9, brazeInstance.setUserAttributeCallCount)
    }

    func testUserAttributesSetOnlyCallsAppboyUserAttributeKeys() {
        let payload = [
            "command_name": "initialize,useridentifier,userAttribute",
            "first_name": "first_name_test",
            "last_name": "last_name_test",
            "email": "email_test",
            "country": "country_test",
            "language": "language_test",
            "home_city": "home_city_test",
            "phone": "phone_test",
            "not_a_user_attribute_key": "123",
            "not_a_user_attribute_key2": "456"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(7, brazeInstance.setUserAttributeCallCount)
    }

    func testCustomAttributesSet() {
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
            "set_custom_attribute": [
                "boolkey": false,
                "intkey": 1,
                "doublekey": 2.0,
                "stringkey": "test_string"]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(4, brazeInstance.setCustomAttributeWithKeyCallCount)
    }

    func testCustomAttributesNotCalled_keyMissing() {
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
            "boolkey": false,
            "intkey": 1,
            "doublekey": 2.0,
            "stringkey": "test_string"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.setCustomAttributeWithKeyCallCount)
    }

    func testUnsetCustomAttributesNotCalled_keyMissing() {
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.setCustomAttributeWithKeyCallCount)
    }

    func testUnsetCustomAttributesNotCalledSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute",
            "unset_custom_attribute": "attribute_key"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.setCustomAttributeWithKeyCallCount)
    }

    func testIncrementCustomAttributeSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,incrementcustomattribute",
            "increment_custom_attribute": ["key1": 1,
                "key2": 2]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.incrementCustomUserAttributeCallCount)
    }

    func testCustomArrayAttributeSet() {
        let payload: [String: Any] = ["command_name": "initialize,setcustomarrayattribute",
            "set_custom_array_attribute": [
                "array_key1": ["value1", "value2", "value3"],
                "array_key2": ["value1", "value2", "value3"],
                "array_key3": ["value1", "value2", "value3"],
            ]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(3, brazeInstance.setCustomAttributeWithKeyCallCount)
    }

    func testAddToCustomAttributeArraySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,appendcustomarrayattribute",
            "append_custom_array_attribute": [
                "array_key1": "value1",
                "array_key2": "value2",
                "array_key3": "value3"
            ]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(3, brazeInstance.addToCustomAttributeArrayWithKeyCallCount)
    }

    func testRemoveCustomAttributeArraySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,removecustomarrayattribute",
            "remove_custom_array_attribute": [
                "array_key1": "value1",
                "array_key2": "value2",
                "array_key3": "value3"
            ]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(3, brazeInstance.removeFromCustomAttributeArrayWithKeyCallCount)
    }

    func testSetEmailNotificationSubscriptionTypeSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
            "email_notification": "optedIn"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setEmailNotificationSubscriptionTypeCallCount)
    }

    func testSetEmailNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
            "email_notification": "UN subscribed"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.setEmailNotificationSubscriptionTypeCallCount)
    }

    func testSetPushNotificationSubscriptionTypeSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
            "push_notification": "subscribed"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setPushNotificationSubscriptionTypeCallCount)
    }

    func testSetPushNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
            "email_notification": "SUBscribed"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.setEmailNotificationSubscriptionTypeCallCount)
    }

    func testLogPurchaseNotCalled_productIdentifierMissing() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "order_currency": "USD",
            "product_unit_price": 12.34
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
    }

    func testLogPurchaseNotCalled_currencyMissing() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": "123",
            "product_unit_price": 12.34
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
    }

    func testLogPurchaseNotCalled_priceMissing() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": "123",
            "order_currency": "USD"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
    }

    func testLogPurchaseSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithPropertiesCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityWithPropertiesCallCount)
    }

    func testLogPurchaseWithQuantitySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "quantity": [5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(1, brazeInstance.logPurchaseWithQuantityCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithPropertiesCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityWithPropertiesCallCount)
    }

    func testLogPurchaseWithPropertiesSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "purchase_properties": ["item1": 123]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityCallCount)
        XCTAssertEqual(1, brazeInstance.logPurchaseWithPropertiesCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityWithPropertiesCallCount)
    }

    func testLogPurchaseWithPropertiesWithQuantitySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": [12.34, 1.99],
            "quantity": [1, 2],
            "purchase_properties": ["item1": 123]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithQuantityCallCount)
        XCTAssertEqual(0, brazeInstance.logPurchaseWithPropertiesCallCount)
        XCTAssertEqual(1, brazeInstance.logPurchaseWithQuantityWithPropertiesCallCount)
    }

    func testDisableSDK() {
        let payload: [String: Any] = ["command_name": "disablesdk"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.disableCallCount)
    }

    func testReenableSDK() {
        let payload: [String: Any] = ["command_name": "enablesdk"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.reEnableCallCount)
    }

    func testWipeData() {
        let payload: [String: Any] = ["command_name": "wipedata"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.wipeDataCallCount)
    }
}
