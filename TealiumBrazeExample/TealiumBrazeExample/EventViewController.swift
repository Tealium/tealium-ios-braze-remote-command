//
//  EventViewController.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/30/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {

    static var arrayCounter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func logEvent(_ sender: UIButton) {
        TealiumHelper.trackEvent(title: "log_custom_event", data: ["event_name": "custom_event"])
    }

    @IBAction func logEventWithProperties(_ sender: Any) {
        TealiumHelper.trackEvent(title: "log_custom_event", data: ["event_name": "level_up", "start_date": "06/14/2020", "high_score": 1200, "current_level": 5])
    }

    @IBAction func setCustomAttributes(_ sender: UIButton) {
        let customAttributes: [String: Any] = [
            "pet": "cat",
            "pet_count": 3,
            "pet_array": ["one", "two", "three"],
            "pet_dictionary": ["key": "value", "anotherKey": "anotherValue"],
            "pet_objects": [["key1": "value1", "anotherKey1": "anotherValue1"],
                            ["key2": "value2", "anotherKey2": "anotherValue2"]]
        ]
        TealiumHelper.trackEvent(title: "custom_attribute", data: customAttributes)

        let customArrayAttributes: [String: Any] = ["pet_names": ["Rosia", "Elsa", "Kawai"]]
        TealiumHelper.trackEvent(title: "custom_array_attribute", data: customArrayAttributes)
    }

    @IBAction func unsetCustomAttributes(_ sender: UIButton) {
        let customAttributes = ["pet_count_unset": "pet_count"]
        TealiumHelper.trackEvent(title: "unset_custom_attribute", data: customAttributes)

        let removeCustomArrayAttributes = ["pet_names_remove": "Kawai"]
        TealiumHelper.trackEvent(title: "remove_custom_array_attribute", data: removeCustomArrayAttributes)
    }


    @IBAction func incrementCustomAttributes(_ sender: Any) {
        let customAttributes = ["pet_count_increment": 2]
        TealiumHelper.trackEvent(title: "increment_custom_attribute", data: customAttributes)

        let appendCustomArrayAttributes: [String: Any] = ["pet_names_append": "petname\(EventViewController.arrayCounter)"]
        EventViewController.arrayCounter += 1
        TealiumHelper.trackEvent(title: "append_custom_array_attribute", data: appendCustomArrayAttributes)
    }


    @IBAction func logPurchase(_ sender: Any) {
        var purchaseInfo = [String: Any]()
        purchaseInfo["product_id"] = ["sku123", "sku345"]
        purchaseInfo["product_quantity"] = [1, 2]
        purchaseInfo["currency_code"] = "usd"
        purchaseInfo["product_unit_price"] = [1.99, 4.99]
        purchaseInfo["rewards_member"] = true
        purchaseInfo["rewards_points_earned"] = 5035
        purchaseInfo["date_joined_program"] = "01/15/2020"
        TealiumHelper.trackEvent(title: "log_purchase", data: purchaseInfo)
    }

    @IBAction func logProductViewed(_ sender: Any) {
        // logProductViewed describes a single product, so its fields are plain scalars (no arrays).
        let data: [String: Any] = [
            "product_id": "sku123",
            "product_name": "Running Shoes",
            "product_variant_id": "red-42",
            "product_viewed_price": 59.99,
            "currency_code": "USD",
            "ecommerce_source": "iOS App"
        ]
        TealiumHelper.trackEvent(title: "log_product_viewed", data: data)
    }

    @IBAction func logCartUpdatedAdd(_ sender: Any) {
        var data = cartData()
        data["cart_action"] = "add"
        TealiumHelper.trackEvent(title: "log_cart_updated", data: data)
    }

    @IBAction func logCartUpdatedRemove(_ sender: Any) {
        var data = cartData()
        data["cart_action"] = "remove"
        TealiumHelper.trackEvent(title: "log_cart_updated", data: data)
    }

    @IBAction func logCartUpdatedReplace(_ sender: Any) {
        var data = cartData()
        data["cart_action"] = "replace"
        // Replace is a full snapshot and requires total_value.
        data["order_total_value"] = 119.98
        TealiumHelper.trackEvent(title: "log_cart_updated", data: data)
    }

    @IBAction func logCheckoutStarted(_ sender: Any) {
        var data = cartData()
        data["checkout_id"] = "checkout-1"
        data["order_total_value"] = 119.98
        TealiumHelper.trackEvent(title: "log_checkout_started", data: data)
    }

    @IBAction func logOrderPlaced(_ sender: Any) {
        var data = cartData()
        data["order_id"] = "order-1"
        data["order_total_value"] = 124.97
        data["order_tax"] = 5.00
        data["order_shipping"] = 4.99
        data["event_metadata"] = ["gift_wrapped": true]
        data["discount_code"] = ["SUMMER10"]
        data["discount_amount"] = [10.0]
        data["discount_type"] = ["percentage"]
        TealiumHelper.trackEvent(title: "log_order_placed", data: data)
    }

    @IBAction func logOrderCancelled(_ sender: Any) {
        var data = cartData()
        data["order_id"] = "order-1"
        data["order_total_value"] = 124.97
        data["cancel_reason"] = "customer_request"
        TealiumHelper.trackEvent(title: "log_order_cancelled", data: data)
    }

    @IBAction func logOrderRefunded(_ sender: Any) {
        var data = cartData()
        data["order_id"] = "order-1"
        data["order_total_value"] = 124.97
        TealiumHelper.trackEvent(title: "log_order_refunded", data: data)
    }

    /// Sample multi-product cart payload shared by the cart / checkout / order demo events.
    /// `cart_product_*` data layer variables map (via braze.json) into the nested `products`
    /// object's parallel arrays, zipped by index -- not a literal array of product objects.
    private func cartData() -> [String: Any] {
        return [
            "cart_id": "cart-1",
            "currency_code": "USD",
            "ecommerce_source": "iOS App",
            "cart_product_id": ["sku123", "sku456"],
            "cart_product_name": ["Running Shoes", "Socks"],
            "cart_variant_id": ["red-42", "black-M"],
            "cart_quantity": [1, 3],
            "cart_price": [59.99, 19.99]
        ]
    }

    /// Altitude and vertical accuracy are optional, but only as a pair: the command falls back to
    /// the 3-argument overload unless both are present.
    @IBAction func setLastKnownLocation(sender: UIButton) {
        var locationInfo = [String: Any]()
        locationInfo["latitude"] = 32.715736
        locationInfo["longitude"] = -117.161087
        locationInfo["horizontal_accuracy"] = 99.00
        locationInfo["altitude"] = 19.00
        locationInfo["vertical_accuracy"] = 12.00
        TealiumHelper.trackEvent(title: "set_location", data: locationInfo)
    }

    @IBAction func logUnknownEvent(_ sender: Any) {
        TealiumHelper.trackEvent(title: "unknown_event", data: nil)
    }

    // MARK: - Consent

    @IBAction func grantFullConsent(_ sender: Any) {
        TealiumHelper.trackEvent(title: "grant_full_consent", data: nil)
    }

    /// Nothing reaches Braze until "Grant Full Consent" re-enables the SDK.
    @IBAction func declineConsent(_ sender: Any) {
        TealiumHelper.trackEvent(title: "decline_consent", data: nil)
    }

    /// Forces an immediate send instead of waiting for Braze's flush interval.
    @IBAction func flushEvents(_ sender: Any) {
        TealiumHelper.trackEvent(title: "flush_events", data: nil)
    }

    // MARK: - Subscription groups

    /// Braze expects the group id from the dashboard, not the group name.
    @IBAction func subscribeToGroup(_ sender: Any) {
        TealiumHelper.trackEvent(title: "subscribe", data: ["subscription_group": "sample-subscription-group-id"])
    }

    @IBAction func unsubscribeFromGroup(_ sender: Any) {
        TealiumHelper.trackEvent(title: "unsubscribe", data: ["subscription_group": "sample-subscription-group-id"])
    }

    // MARK: - Device identifiers

    /// IDFA is a placeholder: the real one needs AdSupport and an ATT prompt, which this demo avoids.
    @IBAction func setDeviceIdentifiers(_ sender: Any) {
        let data: [String: Any] = [
            "ad_tracking_enabled": true,
            "advertiser_identifier": "00000000-0000-0000-0000-000000000000",
            "vendor_identifier": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        TealiumHelper.trackEvent(title: "set_device_identifiers", data: data)
    }

    /// Placeholder signature: a real one is a JWT minted per user by your backend. Braze rejects
    /// invalid signatures once `is_sdk_authentication_enabled` is on, so the example config leaves it off.
    @IBAction func setSdkAuthSignature(_ sender: Any) {
        TealiumHelper.trackEvent(title: "set_sdk_auth_signature",
                                 data: ["sdk_auth_signature": "replace-with-jwt-from-your-backend"])
    }

}
