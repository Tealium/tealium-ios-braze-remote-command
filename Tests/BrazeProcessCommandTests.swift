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

    /// A JSON config written as whole seconds (`"flush_interval": 25`) decodes to `Int`, not
    /// `Double` -- AnyDecodable tries `Int` first -- so reading it as `Double` used to drop the
    /// value silently. Same for the other numeric options, which is why they all go through `optionalValue`.
    ///
    /// Every value here is deliberately off Braze's default (flush 10s, session 30s, trigger 30s),
    /// otherwise a dropped value would still satisfy the assertion.
    func testInitializeWithIntegerNumericConfigValues() {
        let payload: [String: Any] = [
            "command_name": "initialize",
            "api_key": "abc123",
            "custom_endpoint": "test_endpoint",
            "flush_interval": 25,
            "session_timeout": 45,
            "trigger_interval_seconds": 77
        ]
        brazeCommand.processRemoteCommand(with: payload)
        let config = brazeInstance.config
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.api.flushInterval, 25)
        XCTAssertEqual(config!.sessionTimeout, 45)
        XCTAssertEqual(config!.triggerMinimumTimeInterval, 77)
    }

    /// String numbers and bools coerce through `optionalValue`/`convertToBool` the same way the
    /// ecommerce commands do, instead of the direct NSNumber/Bool casts silently dropping them.
    func testCreateConfig_stringNumbersAndBoolsCoerce() {
        let payload: [String: Any] = [
            "command_name": "initialize",
            "api_key": "abc123",
            "custom_endpoint": "test_endpoint",
            "flush_interval": "25",
            "session_timeout": "45",
            "trigger_interval_seconds": "30",
            "use_uuid_as_device_id": "true",
            "forward_universal_links": "true",
            "opt_in_when_push_authorized": "true"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        let config = brazeInstance.config
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.api.flushInterval, 25)
        XCTAssertEqual(config!.sessionTimeout, 45)
        XCTAssertEqual(config!.triggerMinimumTimeInterval, 30)
        XCTAssertTrue(config!.useUUIDAsDeviceId)
        XCTAssertTrue(config!.forwardUniversalLinks)
        XCTAssertTrue(config!.optInWhenPushAuthorized)
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

    /// JSON whole numbers decode as Int; a direct Double cast used to drop the whole location.
    func testSetLastKnownLocation_intCoordinatesCoerce() {
        let payload: [String: Any] = [
            "command_name": "setlastknownlocation",
            "location_latitude": 12, "location_longitude": 123, "location_horizontal_accuracy": 10,
            "location_altitude": 100,
            "location_vertical_accuracy": 5
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.setLastKnownLocationWithAltitudeVerticalAccuracyCallCount)
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
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    func testLogPurchaseProductCurrencySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "product_currency": "USD",
            "product_unit_price": [12.34]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    func testLogPurchaseWithQuantitySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "quantity": [5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([5], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    func testLogPurchaseWithNewProductQtySuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "product_qty": [5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([5], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    func testLogPurchase_quantityLengthMismatchStillLogs() {
        // A quantity array that doesn't match productIds must not drop the whole purchase.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": [12.34, 5.0],
            "quantity": [5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([nil, nil], brazeInstance.loggedPurchaseQuantities)
    }

    func testLogPurchase_quantityElementsLenientlyCoerced() {
        // Numeric strings coerce like the other numeric fields; an unparseable element becomes nil
        // for that product only instead of dropping the whole purchase.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": [12.34, 5.0],
            "quantity": ["5", "abc"]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([5, nil], brazeInstance.loggedPurchaseQuantities)
    }

    func testLogPurchase_stringPricesCoerce() {
        // Data layers often send numbers as strings; logpurchase must coerce them like the
        // ecommerce commands do instead of dropping the purchase.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": ["12.34", 5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([12.34, 5.0], brazeInstance.loggedPurchasePrices)
    }

    func testLogPurchase_fractionalQuantitiesRound() {
        // A lenient cast rounds fractional quantities to nearest rather than rejecting them;
        // out-of-range values still become nil so nothing traps.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["1", "2", "3", "4"],
            "order_currency": "USD",
            "product_unit_price": [1.0, 2.0, 3.0, 4.0],
            "quantity": [2.4, "2.5", 2.8, 1e100]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(4, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([2, 3, 3, nil], brazeInstance.loggedPurchaseQuantities)
    }

    func testLogPurchaseWithPropertiesSuccess() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "purchase_properties": ["item1": 123]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([nil], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([["item1": 123]], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    func testLogPurchaseWithPropertiesWithQuantitySuccess() {
        // Multi-product purchase: quantity+properties must be logged per product, not just the first.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123", "456"],
            "order_currency": "USD",
            "product_unit_price": [12.34, 1.99],
            "quantity": [1, 2],
            "purchase_properties": ["item1": 123]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(2, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual([1, 2], brazeInstance.loggedPurchaseQuantities)
        XCTAssertEqual([["item1": 123], ["item1": 123]], brazeInstance.loggedPurchaseProperties as? [NSDictionary?])
    }

    // MARK: - Ecommerce events
    //
    // `products`/`discounts` are nested dictionaries holding PARALLEL ARRAYS zipped by index --
    // matching tealium-android-firebase-remote-command's items_params convention -- not a literal
    // array of product objects. Canonical keys match the Braze recommended-event schema 1:1 (plain
    // `price`, `quantity`, `currency`, `source`, `total_value`); the logpurchase spellings are also
    // accepted -- see the "Key aliases" tests below.

    func testLogProductViewedSuccess() {
        // logProductViewed describes a single product detail view, so every product field is a
        // plain scalar (no products dictionary -- this event carries no products, unlike
        // cart/checkout/order).
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "image_url": "https://example.com/shoe.png",
            "product_url": "https://example.com/product/sku123",
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.product_viewed", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("sku123", properties?["product_id"] as? String)
        XCTAssertEqual("Running Shoes", properties?["product_name"] as? String)
        XCTAssertEqual("red-42", properties?["variant_id"] as? String)
        XCTAssertEqual(59.99, properties?["price"] as? Double)
        XCTAssertEqual("https://example.com/shoe.png", properties?["image_url"] as? String)
        XCTAssertEqual("https://example.com/product/sku123", properties?["product_url"] as? String)
        XCTAssertEqual("USD", properties?["currency"] as? String)
        XCTAssertEqual("iOS App", properties?["source"] as? String)
    }

    func testLogProductViewedWithTypeIdentifiers() {
        // `type` carries Braze catalog-trigger identifiers (price_drop / back_in_stock). It maps to
        // the SDK's `type` init parameter, which is iOS-only. A successful log proves the
        // throwing initializer accepted the identifiers.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "currency": "USD",
            "source": "iOS App",
            "type": ["price_drop", "back_in_stock"]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.product_viewed", brazeInstance.loggedEcommerceEventNames.last)
    }

    func testLogProductViewedNotCalled_sourceMissing() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "currency": "USD"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_productNameMissing() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "variant_id": "red-42",
            "price": 59.99,
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_arrayRejected() {
        // Scalar-only: logProductViewed carries no products dictionary, so an array value for a
        // product field (even a single-element one) is a caller mistake and fails validation
        // rather than being coerced to a scalar.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123"],
            "product_name": ["Running Shoes"],
            "variant_id": ["red-42"],
            "price": [59.99],
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_multiElementArrayRejected() {
        // A multi-element array is likewise rejected, never fanned out into multiple events.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes", "Winter Jacket"],
            "variant_id": ["red-42", "blue-L"],
            "price": [59.99, 129.99],
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    /// Builds the nested `products` dictionary -- parallel arrays zipped by index -- from flat
    /// per-product field dictionaries, matching what EcommerceEventParser reads from a real
    /// payload.
    private func productsDictionary(_ products: [[String: Any]]) -> [String: Any] {
        [
            "product_id": products.map { $0["product_id"] },
            "product_name": products.map { $0["product_name"] },
            "variant_id": products.map { $0["variant_id"] },
            "price": products.map { $0["price"] },
            "quantity": products.map { $0["quantity"] }
        ]
    }

    func testLogCartUpdatedAddSuccess() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "add",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 2]
            ])
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
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "remove",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
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
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "replace",
            "total_value": 119.98,
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1],
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 3]
            ])
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

    func testLogCartUpdated_actionOmittedTreatedAsReplace() {
        // The Braze schema treats an omitted action as a full-cart snapshot -- hence total_value being
        // documented as required "when action is omitted or replace".
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "total_value": 59.99,
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("replace", brazeInstance.loggedEcommerceEventProperties.last?["action"] as? String)
    }

    func testLogCartUpdatedNotCalled_unrecognizedAction() {
        // A typo must not fall back to replace: that logged an action the customer never asked for,
        // and reported the resulting missing total_value instead of the bad action.
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "ad",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdatedNotCalled_nonStringAction() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": 1,
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdated_actionCasingAndWhitespaceTolerated() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": " Add ",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("add", brazeInstance.loggedEcommerceEventProperties.last?["action"] as? String)
    }

    func testLogCartUpdatedReplace_partialProductMetadata() {
        // Regression guard: a whole-array cast (`products["metadata"] as? [[String: Any]]`) would
        // fail outright once ANY element is non-dictionary (e.g. NSNull for a product with no
        // metadata), silently dropping metadata for every product rather than just that one.
        var products = productsDictionary([
            ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1],
            ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 3]
        ])
        products["metadata"] = [["color": "red"], NSNull()]
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "replace",
            "total_value": 119.98,
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let resultProducts = brazeInstance.loggedEcommerceEventProperties.last?["products"] as? [[String: Any]]
        XCTAssertEqual(2, resultProducts?.count)
        let firstMetadata = resultProducts?.first?["metadata"] as? [String: Any]
        XCTAssertEqual("red", firstMetadata?["color"] as? String)
        XCTAssertNil(resultProducts?.last?["metadata"])
    }

    func testLogCartUpdatedNotCalled_cartIdMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "currency": "USD",
            "source": "iOS App",
            "action": "add",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 2]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCartUpdatedNotCalled_productsMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "add"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogCheckoutStartedSuccess() {
        let payload: [String: Any] = ["command_name": "logcheckoutstarted",
            "checkout_id": "checkout-1",
            "cart_id": "cart-1",
            "total_value": 59.99,
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
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
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedSuccess() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "cart_id": "cart-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "tax": 5.00,
            "shipping": 4.99,
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1],
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
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

    func testLogOrderPlacedWithDiscounts() {
        // `discounts` is a nested dictionary of parallel arrays (code/amount/type), zipped by index
        // like `products`. Braze's OrderPlacedEvent.discounts is typed [Any]?, so the entries are
        // forwarded as [String: Any] dictionaries.
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "total_discounts": 15.0,
            "discounts": [
                "code": ["SUMMER10", "VIP5"],
                "amount": [10.0, 5.0],
                "type": ["percentage", "fixed"]
            ],
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.order_placed", brazeInstance.loggedEcommerceEventNames.last)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual(15.0, properties?["total_discounts"] as? Double)
        let discounts = properties?["discounts"] as? [[String: Any]]
        XCTAssertEqual(2, discounts?.count)
        XCTAssertEqual("SUMMER10", discounts?.first?["code"] as? String)
        // The Braze doc types discount `amount` as a Float, so the parser emits it as a NUMBER
        // (Double/NSNumber), not a String.
        XCTAssertNil(discounts?.first?["amount"] as? String)
        XCTAssertEqual(10.0, discounts?.first?["amount"] as? Double)
        XCTAssertEqual("percentage", discounts?.first?["type"] as? String)
    }

    func testLogOrderPlacedWithDiscountAmountCoercion() {
        // discount `amount` coerces numeric strings like other numeric fields, and per-element
        // (not whole-array) rejects Bool -- a mixed array still recovers the valid entries.
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "discounts": [
                "code": ["SUMMER10", "VIP5", "BADAMT"],
                "amount": [10.0, "5", true],
                "type": ["percentage", "fixed", "fixed"]
            ],
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        let discounts = brazeInstance.loggedEcommerceEventProperties.last?["discounts"] as? [[String: Any]]
        XCTAssertEqual(10.0, discounts?[0]["amount"] as? Double)
        XCTAssertEqual(5.0, discounts?[1]["amount"] as? Double)
        XCTAssertNil(discounts?[2]["amount"])
    }

    func testLogOrderPlacedNotCalled_orderIdMissing() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedNotCalled_totalValueMissing() {
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    // MARK: Key aliases
    //
    // Either spelling works on both paths: the logpurchase keys (`product_currency`/`order_currency`,
    // `product_unit_price`, `product_qty`) and the Braze ones (`currency`, `price`, `quantity`).

    func testLogProductViewed_orderCurrencyAliasAccepted() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "order_currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedEcommerceEventProperties.last?["currency"] as? String)
    }

    func testLogProductViewed_productCurrencyAliasAccepted() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "product_currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedEcommerceEventProperties.last?["currency"] as? String)
    }

    func testLogProductViewed_productUnitPriceAliasAccepted() {
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "product_unit_price": 59.99,
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual(59.99, brazeInstance.loggedEcommerceEventProperties.last?["price"] as? Double)
    }

    func testLogProductViewed_canonicalKeyWinsOverAlias() {
        // Both spellings present: `currency` is first in the accepted order, so it wins.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "currency": "USD",
            "product_currency": "EUR",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedEcommerceEventProperties.last?["currency"] as? String)
    }

    func testLogCartUpdated_productArrayAliasesAccepted() {
        // The nested `products` arrays resolve through the same lookup, so they accept the logpurchase
        // spellings too.
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "product_currency": "USD",
            "source": "iOS App",
            "action": "add",
            "products": [
                "product_id": ["sku123"],
                "product_name": ["Running Shoes"],
                "variant_id": ["red-42"],
                "product_unit_price": [59.99],
                "product_qty": [2]
            ]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual("USD", properties?["currency"] as? String)
        let products = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(59.99, products?.first?["price"] as? Double)
        XCTAssertEqual(2, products?.first?["quantity"] as? Int)
    }

    func testLogPurchase_canonicalEcommerceKeysAccepted() {
        // Mirror case: logpurchase accepts the canonical ecommerce spellings, so a customer who
        // mapped `currency`/`price`/`quantity` for the ecommerce events needs no second mapping.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "currency": "USD",
            "price": [12.34],
            "quantity": [5]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedPurchaseCurrencies.last)
    }

    func testLogPurchase_canonicalCurrencyWinsOverProductCurrency() {
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "currency": "USD",
            "product_currency": "EUR",
            "product_unit_price": [12.34]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedPurchaseCurrencies.last)
    }

    func testLogPurchase_quantityWinsOverProductQty() {
        // Precedence guard: `quantity` is the canonical Braze spelling and listed first in
        // `keyAliases`, so it wins over the older logpurchase spelling `product_qty` when a
        // payload carries both.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "order_currency": "USD",
            "product_unit_price": [12.34],
            "product_qty": [5],
            "quantity": [99]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual(99, brazeInstance.loggedPurchaseQuantities.last)
    }

    func testLogPurchase_productCurrencyWinsOverOrderCurrency() {
        // Alternate spellings are tried in order, so the pre-existing logpurchase precedence
        // (`product_currency` before `order_currency`) is preserved.
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
            "product_id": ["123"],
            "product_currency": "USD",
            "order_currency": "EUR",
            "product_unit_price": [12.34]
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logPurchaseCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedPurchaseCurrencies.last)
    }

    func testLogCartUpdatedReplaceNotCalled_totalValueMissing() {
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "replace",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1],
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 3]
            ])
            // total_value intentionally omitted; replace requires it.
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlacedNotCalled_mismatchedProductArrayLengths() {
        let products: [String: Any] = [
            "product_id": ["sku123", "sku456"],
            "product_name": ["Running Shoes"], // mismatched length vs the other arrays
            "variant_id": ["red-42", "black-M"],
            "price": [59.99, 19.99],
            "quantity": [1, 1]
        ]
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    // MARK: - Order Cancelled / Refunded (custom events)

    func testLogOrderCancelledSuccess() {
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "cancel_reason": "customer_request",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
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

    func testLogOrderCancelledWithOptionalFieldsAndDiscounts() {
        // order_cancelled has no typed SDK class, so subtotal_value/tax/shipping/discounts are
        // forwarded through the logCustomEvent wire payload (unlike the typed cart/checkout/order
        // events, which cannot carry subtotal/tax/shipping on iOS's counterpart Android SDK).
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 79.98,
            "subtotal_value": 69.99,
            "tax": 5.0,
            "shipping": 4.99,
            "currency": "USD",
            "source": "iOS App",
            "cancel_reason": "customer_request",
            "total_discounts": 10.0,
            "discounts": [
                "code": ["SUMMER10"],
                "amount": [10.0],
                "type": ["percentage"]
            ],
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
        XCTAssertEqual("ecommerce.order_cancelled", brazeInstance.lastCustomEventName)
        let properties = brazeInstance.lastCustomEventProperties
        XCTAssertEqual(69.99, properties?["subtotal_value"] as? Double)
        XCTAssertEqual(5.0, properties?["tax"] as? Double)
        XCTAssertEqual(4.99, properties?["shipping"] as? Double)
        XCTAssertEqual(10.0, properties?["total_discounts"] as? Double)
        let discounts = properties?["discounts"] as? [[String: Any]]
        XCTAssertEqual(1, discounts?.count)
        XCTAssertEqual("SUMMER10", discounts?.first?["code"] as? String)
        // Discount `amount` is emitted as a NUMBER (Float per the Braze doc), not a String.
        XCTAssertNil(discounts?.first?["amount"] as? String)
        XCTAssertEqual(10.0, discounts?.first?["amount"] as? Double)
    }

    func testLogOrderCancelledNotCalled_cancelReasonMissing() {
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogOrderRefundedSuccess() {
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "order_id": "order-2",
            "total_value": 39.99,
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
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
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    // MARK: - Regression: string→number coercion, currency uppercase, scalar type, per-item validation

    func testLogOrderPlaced_stringNumbersCoerced() {
        // Tealium data layers routinely send numbers as strings. total_value/tax as string scalars and
        // price/quantity as string arrays must coerce, not throw + drop the whole event (Android
        // already coerces; iOS previously threw typeMismatch here).
        var products = productsDictionary([
            ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": "59.99", "quantity": "1"]
        ])
        products["price"] = ["59.99"]
        products["quantity"] = ["1"]
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": "59.99",
            "tax": "5.00",
            "currency": "USD",
            "source": "iOS App",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let properties = brazeInstance.loggedEcommerceEventProperties.last
        XCTAssertEqual(59.99, properties?["total_value"] as? Double)
        let resultProducts = properties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, resultProducts?.count)
    }

    func testLogOrderPlaced_currencyLowercaseUppercased() {
        // Braze validates ISO-4217 canonical uppercase; a lowercase "usd" would throw on construct
        // and drop the event. The parser uppercases it so the event still logs.
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 59.99,
            "currency": "usd",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("USD", brazeInstance.loggedEcommerceEventProperties.last?["currency"] as? String)
    }

    func testLogProductViewed_scalarTypeAccepted() {
        // A scalar `type` string (not an array) must be wrapped into a single-element type
        // array rather than silently dropped.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": 59.99,
            "currency": "USD",
            "source": "iOS App",
            "type": "price_drop"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogProductViewedNotCalled_priceMissing() {
        // Parity with Android, which covers missing-price on product_viewed.
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logEcommerceEventCallCount)
    }

    func testLogOrderPlaced_discountAmountEmittedAsNumber() {
        // The Braze "Log eCommerce events" doc types discount `amount` as a Float, so the parser emits
        // it as a NUMBER (not a String). This also proves the [String: Any] discount dict with a Double
        // amount round-trips through serializedCustomEventProperties() without throwing
        // discountEntryNotSerializable (a Double is JSON-serializable).
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 79.98,
            "currency": "USD",
            "source": "iOS App",
            "discounts": [
                "code": ["SUMMER10"],
                "amount": [10.0],
                "type": ["percentage"]
            ],
            "products": productsDictionary([
                ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let discounts = brazeInstance.loggedEcommerceEventProperties.last?["discounts"] as? [[String: Any]]
        XCTAssertNil(discounts?.first?["amount"] as? String)
        XCTAssertEqual(10.0, discounts?.first?["amount"] as? Double)
    }

    func testLogOrderRefunded_discountAmountEmittedAsNumber() {
        // order_refunded forwards discounts through the raw custom-event JSON; assert the amount is a
        // NUMBER there too (previously order_refunded discounts were unasserted).
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "order_id": "order-2",
            "total_value": 39.99,
            "currency": "USD",
            "source": "iOS App",
            "total_discounts": 5.0,
            "discounts": [
                "code": ["VIP5"],
                "amount": [5.0],
                "type": ["fixed"]
            ],
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
        let discounts = brazeInstance.lastCustomEventProperties?["discounts"] as? [[String: Any]]
        XCTAssertEqual(1, discounts?.count)
        XCTAssertEqual("VIP5", discounts?.first?["code"] as? String)
        XCTAssertNil(discounts?.first?["amount"] as? String)
        XCTAssertEqual(5.0, discounts?.first?["amount"] as? Double)
    }

    func testLogOrderPlaced_mixedNativeAndStringProductArrays() {
        // I2: a mixed native+string price/quantity array matches neither [NSNumber] nor [String] as a
        // whole; per-element coercion must still build the event with all products (Android parity).
        var products = productsDictionary([
            ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": 59.99, "quantity": 1],
            ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 2]
        ])
        products["price"] = [59.99, "19.99"]
        products["quantity"] = [1, "2"]
        let payload: [String: Any] = ["command_name": "logorderplaced",
            "order_id": "order-1",
            "total_value": 99.97,
            "currency": "USD",
            "source": "iOS App",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        let resultProducts = brazeInstance.loggedEcommerceEventProperties.last?["products"] as? [[String: Any]]
        XCTAssertEqual(2, resultProducts?.count)
    }

    func testLogCartUpdated_stringNumbersCoerced() {
        // String→number coercion parity for cart_updated (total_value/price/quantity as strings).
        var products = productsDictionary([
            ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": "59.99", "quantity": "1"]
        ])
        products["price"] = ["59.99"]
        products["quantity"] = ["1"]
        let payload: [String: Any] = ["command_name": "logcartupdated",
            "cart_id": "cart-1",
            "currency": "USD",
            "source": "iOS App",
            "action": "add",
            "total_value": "59.99",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.cart_updated", brazeInstance.loggedEcommerceEventNames.last)
    }

    func testLogCheckoutStarted_stringNumbersCoerced() {
        // String→number coercion parity for checkout_started.
        var products = productsDictionary([
            ["product_id": "sku123", "product_name": "Running Shoes", "variant_id": "red-42", "price": "59.99", "quantity": "1"]
        ])
        products["price"] = ["59.99"]
        products["quantity"] = ["1"]
        let payload: [String: Any] = ["command_name": "logcheckoutstarted",
            "checkout_id": "checkout-1",
            "total_value": "59.99",
            "currency": "USD",
            "source": "iOS App",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.checkout_started", brazeInstance.loggedEcommerceEventNames.last)
    }

    func testLogProductViewed_stringPriceCoerced() {
        // String→number coercion parity for product_viewed (scalar price sent as a numeric string).
        let payload: [String: Any] = ["command_name": "logproductviewed",
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "variant_id": "red-42",
            "price": "59.99",
            "currency": "USD",
            "source": "iOS App"
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logEcommerceEventCallCount)
        XCTAssertEqual("ecommerce.product_viewed", brazeInstance.loggedEcommerceEventNames.last)
        XCTAssertEqual(59.99, brazeInstance.loggedEcommerceEventProperties.last?["price"] as? Double)
    }

    func testLogOrderCancelled_invalidProductSkippedNotWholeEvent() {
        // A single product the SDK rejects (blank product_id) is skipped; the valid line item and the
        // event survive, rather than the whole event being dropped.
        let products = productsDictionary([
            ["product_id": "", "product_name": "Bad", "variant_id": "x", "price": 1.0, "quantity": 1],
            ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
        ])
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 20.99,
            "currency": "USD",
            "source": "iOS App",
            "cancel_reason": "customer_request",
            "products": products
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logCustomEventWithPropertiesCallCount)
        let resultProducts = brazeInstance.lastCustomEventProperties?["products"] as? [[String: Any]]
        XCTAssertEqual(1, resultProducts?.count)
        XCTAssertEqual("sku456", resultProducts?.first?["product_id"] as? String)
    }

    // MARK: Custom event schema validation (order_cancelled / order_refunded)
    //
    // No typed SDK class, so nothing validates these on the way out -- Braze drops an invalid payload
    // after ingestion. The parser applies the documented schema rules itself to fail visibly instead.

    func testLogOrderCancelledNotCalled_allProductsInvalid() {
        // Every product rejected leaves an empty products array, which Braze requires to be
        // non-empty (the typed events raise ValidationError.emptyProductsArray).
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "order-1",
            "total_value": 20.99,
            "currency": "USD",
            "source": "iOS App",
            "cancel_reason": "customer_request",
            "products": productsDictionary([
                ["product_id": "", "product_name": "Bad", "variant_id": "x", "price": 1.0, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogOrderCancelledNotCalled_blankOrderId() {
        let payload: [String: Any] = ["command_name": "logordercancelled",
            "order_id": "   ",
            "total_value": 20.99,
            "currency": "USD",
            "source": "iOS App",
            "cancel_reason": "customer_request",
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogOrderRefundedNotCalled_negativeTotalValue() {
        // Braze wants the refunded amount as a positive figure and applies the decrement itself.
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "order_id": "order-1",
            "total_value": -20.99,
            "currency": "USD",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
        ]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(0, brazeInstance.logCustomEventWithPropertiesCallCount)
    }

    func testLogOrderRefundedNotCalled_blankCurrency() {
        let payload: [String: Any] = ["command_name": "logorderrefunded",
            "order_id": "order-1",
            "total_value": 20.99,
            "currency": "",
            "source": "iOS App",
            "products": productsDictionary([
                ["product_id": "sku456", "product_name": "Socks", "variant_id": "black-M", "price": 19.99, "quantity": 1]
            ])
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

    func testLogout() {
        let payload: [String: Any] = ["command_name": "logout"]
        brazeCommand.processRemoteCommand(with: payload)
        XCTAssertEqual(1, brazeInstance.logoutCallCount)
    }
}
