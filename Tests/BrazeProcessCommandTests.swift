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
    
    func testSetIdentifierForAdvertiserSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,setidentifierforadvertiser",
            "advertiser_identifier": "test_id"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setIdentifierForAdvertiserCallCount)
    }
    
    func testSetIdentifierVendorSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,setidentifierforvendor",
            "vendor_identifier": "test_id"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setIdentifierForVendorCallCount)
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

    func testLogPurchaseProductCurrencySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "product_currency": "USD",
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

    func testLogPurchaseWithNewProductQtySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "product_qty": [5]
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

    // MARK: - Ecommerce events

    func testLogProductViewedSuccess() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_unit_price": [59.99],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.product_viewed", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("sku123", properties?["product_id"] as? String)
        XCTAssertEqual("Running Shoes", properties?["product_name"] as? String)
        XCTAssertEqual("red-42", properties?["variant_id"] as? String)
        XCTAssertEqual(59.99, properties?["price"] as? Double)
        XCTAssertEqual("USD", properties?["currency"] as? String)
        XCTAssertEqual("iOS App", properties?["source"] as? String)
    }

    func testLogProductViewedNotCalled_sourceMissing() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_unit_price": [59.99],
            "product_currency": "USD"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_productNameMissing() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "variant_id": ["red-42"],
            "product_unit_price": [59.99],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedScalarPayloadSuccess() {
        // Reviewer-requested leniency: scalar (non-array) product_id/product_name/variant_id/
        // product_unit_price must be accepted, not just single-element arrays.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "product_unit_price": 59.99,
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.product_viewed", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("sku123", properties?["product_id"] as? String)
        XCTAssertEqual("Running Shoes", properties?["product_name"] as? String)
        XCTAssertEqual("red-42", properties?["variant_id"] as? String)
        XCTAssertEqual(59.99, properties?["price"] as? Double)
        XCTAssertEqual("USD", properties?["currency"] as? String)
        XCTAssertEqual("iOS App", properties?["source"] as? String)
    }

    func testLogProductViewedMixedShapePayloadSuccess() {
        // Field-by-field independence: some fields scalar, some single-element array, in the same
        // payload -- both shapes accepted simultaneously (single-product case).
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "product_name": "Running Shoes",
            "variant_id": ["red-42"],
            "product_unit_price": 59.99,
            "image_url": "https://example.com/shoe.png",
            "product_url": ["https://example.com/product/sku123"],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("sku123", properties?["product_id"] as? String)
        XCTAssertEqual("Running Shoes", properties?["product_name"] as? String)
        XCTAssertEqual("red-42", properties?["variant_id"] as? String)
        XCTAssertEqual(59.99, properties?["price"] as? Double)
        XCTAssertEqual("https://example.com/shoe.png", properties?["image_url"] as? String)
        XCTAssertEqual("https://example.com/product/sku123", properties?["product_url"] as? String)
    }

    func testLogProductViewedMultipleProductsFiresMultipleEvents() {
        // Array with N>1 elements fires N separate ecommerce.product_viewed events, one per
        // product, mirroring the existing logPurchase loop and the Android SDK precedent
        // (BrazeRemoteCommand.java's productId instanceof JSONArray branch).
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Winter Jacket"],
            "variant_id": ["red-42", "blue-L"],
            "product_unit_price": [59.99, 129.99],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("sku123", brazeInstance.loggedEcommerceEventProperties[0]["product_id"] as? String)
        XCTAssertEqual(59.99, brazeInstance.loggedEcommerceEventProperties[0]["price"] as? Double)
        XCTAssertEqual("sku456", brazeInstance.loggedEcommerceEventProperties[1]["product_id"] as? String)
        XCTAssertEqual(129.99, brazeInstance.loggedEcommerceEventProperties[1]["price"] as? Double)
    }

    func testLogProductViewedMultipleProducts_partialImageUrl() {
        // Regression guard: a whole-array cast (`payload["image_url"] as? [String]`) would fail
        // outright once ANY element is non-String (e.g. NSNull for a missing value), silently
        // dropping image_url for every product rather than just the one missing it.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Winter Jacket"],
            "variant_id": ["red-42", "blue-L"],
            "product_unit_price": [59.99, 129.99],
            "image_url": ["https://example.com/shoe.png", NSNull()],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("https://example.com/shoe.png", brazeInstance.loggedEcommerceEventProperties[0]["image_url"] as? String)
        XCTAssertNil(brazeInstance.loggedEcommerceEventProperties[1]["image_url"])
    }

    func testLogProductViewedNotCalled_mismatchedArrayLengths() {
        // Defensive guard: inconsistent array lengths across product fields fail the whole
        // event rather than guessing which elements pair together.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42", "blue-L"],
            "product_unit_price": [59.99, 129.99],
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdatedAddSuccess() {
        let payload: [String: Any] = ["command_name": "logcartupdatedadd",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [2],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.cart_updated", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("cart-1", properties?["cart_id"] as? String)
        XCTAssertEqual("add", properties?["action"] as? String)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, products?.count)
        XCTAssertEqual("sku123", products?.first?["product_id"] as? String)
        XCTAssertEqual(2, products?.first?["quantity"] as? Int)
    }

    func testLogCartUpdatedRemoveSuccess() {
        let payload: [String: Any] = ["command_name": "logcartupdatedremove",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.cart_updated", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("cart-1", properties?["cart_id"] as? String)
        XCTAssertEqual("remove", properties?["action"] as? String)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, products?.count)
        XCTAssertEqual("sku123", products?.first?["product_id"] as? String)
    }

    func testLogCartUpdatedReplaceSuccess() {
        let payload: [String: Any] = ["command_name": "logcartupdatedreplace",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "total_value": 119.98,
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Socks"],
            "variant_id": ["red-42", "black-M"],
            "product_qty": [1, 3],
            "product_unit_price": [59.99, 19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.cart_updated", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("cart-1", properties?["cart_id"] as? String)
        XCTAssertEqual("replace", properties?["action"] as? String)
        XCTAssertEqual(119.98, properties?["total_value"] as? Double)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(2, products?.count)
    }

    func testLogCartUpdatedReplace_partialProductMetadata() {
        // Regression guard: a whole-array cast (`payload["product_metadata"] as? [[String: Any]]`)
        // would fail outright once ANY element is non-dictionary (e.g. NSNull for a product with
        // no metadata), silently dropping metadata for every product rather than just that one.
        let payload: [String: Any] = ["command_name": "logcartupdatedreplace",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "total_value": 119.98,
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Socks"],
            "variant_id": ["red-42", "black-M"],
            "product_qty": [1, 3],
            "product_unit_price": [59.99, 19.99],
            "product_metadata": [["color": "red"], NSNull()]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let products = brazeInstance.loggedEcommerceEventProperties.last?["products"] as? [[String: Any]]
        XCTAssertEqual(2, products?.count)
        let firstMetadata = products?.first?["metadata"] as? [String: Any]
        XCTAssertEqual("red", firstMetadata?["color"] as? String)
        XCTAssertNil(products?.last?["metadata"])
    }

    func testLogCartUpdatedNotCalled_cartIdMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdatedadd",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [2],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdatedNotCalled_productsMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdatedadd",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCheckoutStartedSuccess() {
        let payload: [String: Any] = ["command_name": "logcheckoutstarted",
            "checkout_id": "checkout-1",
            "cart_id": "cart-1",
            "total_value": 59.99,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.checkout_started", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("checkout-1", properties?["checkout_id"] as? String)
        XCTAssertEqual("cart-1", properties?["cart_id"] as? String)
        XCTAssertEqual(59.99, properties?["total_value"] as? Double)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, products?.count)
        XCTAssertEqual("sku123", products?.first?["product_id"] as? String)
    }

    func testLogCheckoutStartedNotCalled_checkoutIdMissing() {
        let payload: [String: Any] = ["command_name": "logcheckoutstarted",
            "total_value": 59.99,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedSuccess() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "cart_id": "cart-1",
            "total_value": 79.98,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "tax": 5.00,
            "shipping": 4.99,
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Socks"],
            "variant_id": ["red-42", "black-M"],
            "product_qty": [1, 1],
            "product_unit_price": [59.99, 19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.order_placed", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("order-1", properties?["order_id"] as? String)
        XCTAssertEqual("cart-1", properties?["cart_id"] as? String)
        XCTAssertEqual(79.98, properties?["total_value"] as? Double)
        XCTAssertEqual(5.00, properties?["tax"] as? Double)
        XCTAssertEqual(4.99, properties?["shipping"] as? Double)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(2, products?.count)
        XCTAssertEqual("sku123", products?.first?["product_id"] as? String)
    }

    func testLogOrderPlacedNotCalled_orderIdMissing() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "total_value": 79.98,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedNotCalled_totalValueMissing() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_orderCurrencyNotAFallback() {
        // Unlike logPurchase, ecommerce events do NOT accept the legacy `order_currency` key --
        // only `product_currency`.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_unit_price": [59.99],
            "order_currency": "USD",
            "ecommerce_source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdatedReplaceNotCalled_totalValueMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdatedreplace",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Socks"],
            "variant_id": ["red-42", "black-M"],
            "product_qty": [1, 3],
            "product_unit_price": [59.99, 19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedNotCalled_mismatchedProductArrayLengths() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 79.98,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42", "black-M"],
            "product_qty": [1, 1],
            "product_unit_price": [59.99, 19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    // MARK: - Order Cancelled / Refunded (custom events)

    func testLogOrderCancelledSuccess() {
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 79.98,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "cancel_reason": "customer_request",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
        XCTAssertEqual("ecommerce.order_cancelled", brazeInstance.lastCustomEventName)
        let properties = brazeInstance.lastCustomEventProperties
        XCTAssertEqual("order-1", properties?["order_id"] as? String)
        XCTAssertEqual("customer_request", properties?["cancel_reason"] as? String)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, products?.count)
        XCTAssertEqual("sku123", products?.first?["product_id"] as? String)
    }

    func testLogOrderCancelledNotCalled_cancelReasonMissing() {
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 79.98,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "product_qty": [1],
            "product_unit_price": [59.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogOrderRefundedSuccess() {
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "order_id": "order-2",
            "total_value": 39.99,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku456"],
            "product_name": ["Socks"],
            "variant_id": ["black-M"],
            "product_qty": [1],
            "product_unit_price": [19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
        XCTAssertEqual("ecommerce.order_refunded", brazeInstance.lastCustomEventName)
        let properties = brazeInstance.lastCustomEventProperties
        XCTAssertEqual("order-2", properties?["order_id"] as? String)
        XCTAssertNil(properties?["cancel_reason"])
    }

    func testLogOrderRefundedNotCalled_orderIdMissing() {
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "total_value": 39.99,
            "product_currency": "USD",
            "ecommerce_source": "iOS App",
            "product_id": ["sku456"],
            "product_name": ["Socks"],
            "variant_id": ["black-M"],
            "product_qty": [1],
            "product_unit_price": [19.99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testExistingLogPurchaseUnaffectedByEcommerce() {
        let payload: [String: Any] = ["command_name": "logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
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
