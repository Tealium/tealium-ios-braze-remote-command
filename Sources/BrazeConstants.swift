//
//  BrazeConstants.swift
//  TealiumBraze
//
//  Created by Christina S on 9/21/20.
//  Copyright © 2020 Tealium. All rights reserved.
//

import Foundation

public enum BrazeConstants {

    static let commandName = "command_name"
    static let separator: Character = ","
    static let commandId = "braze"
    static let description = "Braze Remote Command"
    static let version = "3.7.0"

    enum Commands: String {
        case initialize = "initialize"
        case userIdentifier = "useridentifier"
        case setSdkAuthSignature = "setsdkauthsignature"
        case userAlias = "useralias"
        case userAttribute = "userattribute"
        case setCustomAttribute = "setcustomattribute"
        case unsetCustomAttribute = "unsetcustomattribute"
        case setCustomArrayAttribute = "setcustomarrayattribute"
        case appendCustomArrayAttribute = "appendcustomarrayattribute"
        case removeCustomArrayAttribute = "removecustomarrayattribute"
        case emailNotification = "emailnotification"
        case pushNotification = "pushnotification"
        case incrementCustomAttribute = "incrementcustomattribute"
        case logCustomEvent = "logcustomevent"
        case logPurchase = "logpurchase"
        // Ecommerce recommended events
        case logProductViewed = "logproductviewed"
        case logCartUpdatedAdd = "logcartupdatedadd"
        case logCartUpdatedRemove = "logcartupdatedremove"
        case logCartUpdatedReplace = "logcartupdatedreplace"
        case logCheckoutStarted = "logcheckoutstarted"
        case logOrderPlaced = "logorderplaced"
        case logOrderCancelled = "logordercancelled"
        case logOrderRefunded = "logorderrefunded"
        case setAdTrackingEnabled = "setadtrackingenabled"
        case setIdentifierForAdvertiser = "setidentifierforadvertiser"
        case setIdentifierForVendor = "setidentifierforvendor"
        case setLastKnownLocation = "setlastknownlocation"
        case enableSDK = "enablesdk"
        case disableSDK = "disablesdk"
        case wipeData = "wipedata"
        case flush = "flush"
        case addToSubsriptionGroup = "addtosubscriptiongroup"
        case removeFromSubscriptionGroup = "removefromsubscriptiongroup"
    }

    enum Keys {
        static let apiKey = "api_key"
        static let isSdkAuthEnabled = "is_sdk_authentication_enabled"
        static let sdkAuthSignature = "sdk_authentication_signature"
        static let userIdentifier = "user_id"
        static let userAlias = "user_alias"
        static let aliasLabel = "alias_label"
        static let customAttribute = "set_custom_attribute"
        static let customArrayAttribute = "set_custom_array_attribute"
        static let appendCustomArrayAttribute = "append_custom_array_attribute"
        static let removeCustomArrayAttribute = "remove_custom_array_attribute"
        static let unsetCustomAttribute = "unset_custom_attribute"
        static let incrementCustomAttribute = "increment_custom_attribute"
        static let emailNotification = "email_notification"
        static let pushNotification = "push_notification"
        static let eventKey = "event"
        static let eventProperties = "event_properties"
        static let eventName = "event_name"

        // logPurchase keys (legacy, distinct from the recommended ecommerce events in `Ecommerce`).
        static let productIdentifier = "product_id"
        static let currency = "order_currency" // Legacy currency key (fallback for `productCurrency`).
        static let productCurrency = "product_currency"
        static let price = "product_unit_price"
        static let quantity = "quantity" // Legacy quantity key (fallback for `productQuantity`).
        static let productQuantity = "product_qty"
        static let purchaseKey = "purchase"
        static let purchaseProperties = "purchase_properties"

        static let sessionTimeout = "session_timeout"
        static let enableAutomaticLocation = "enable_automatic_location"
        static let enableGeofences = "enable_geofences"
        static let enableAutomaticGeofences = "enable_automatic_geofences"
        static let triggerIntervalSeconds = "trigger_interval_seconds"
        static let latitude = "location_latitude"
        static let longitude = "location_longitude"
        static let horizontalAccuracy = "location_horizontal_accuracy"
        static let altitude = "location_altitude"
        static let verticalAccuracy = "location_vertical_accuracy"
        static let requestProcessingPolicy = "request_processing_policy"
        static let flushInterval = "flush_interval"
        static let adTrackingEnabled = "ad_tracking_enabled"
        static let advertiserIdentifier = "advertiser_identifier"
        static let vendorIdentifier = "vendor_identifier"
        static let customEndpoint = "custom_endpoint"
        static let deviceOptions = "device_options"
        static let pushStoryIdentifier = "push_story_identifier"
        static let subscriptionGroupId = "subscription_group_id"
        static let forwardUniversalLinks = "forward_universal_links"
        static let optInWhenPushAuthorized = "opt_in_when_push_authorized"
        static let useUUIDAsDeviceId = "use_uuid_as_device_id"
    }

    /// INPUT payload keys for the recommended ecommerce events (`logProductViewed`,
    /// `logCartUpdated*`, `logCheckoutStarted`, `logOrderPlaced`, `logOrderCancelled`,
    /// `logOrderRefunded`). Key names are unified with the Android remote command. Distinct from the
    /// legacy `logPurchase` keys in `Keys` and from the Braze OUTPUT wire names in `EcommerceWireKeys`.
    enum Ecommerce {
        // Event-level fields.
        static let currency = "ecommerce_currency"
        static let source = "ecommerce_source"
        static let totalValue = "ecommerce_total_value"
        static let subtotalValue = "ecommerce_subtotal_value"
        static let tax = "ecommerce_tax"
        static let shipping = "ecommerce_shipping"
        static let totalDiscounts = "ecommerce_total_discounts"
        static let discounts = "discounts"
        static let metadata = "ecommerce_properties" // event-level metadata
        static let cartId = "cart_id"
        static let checkoutId = "checkout_id"
        static let orderId = "order_id"
        static let cancelReason = "cancel_reason"
        static let typeIdentifiers = "type_identifiers" // logProductViewed only

        // Product-level fields. For cart/checkout/order events these are PARALLEL TOP-LEVEL ARRAYS
        // (product_id: [...], product_unit_price: [...], ...) zipped by index; for logProductViewed
        // (no products array) they are read as top-level scalars.
        static let productId = "product_id"
        static let productName = "product_name"
        static let variantId = "variant_id"
        static let price = "product_unit_price"
        static let quantity = "product_qty"
        static let quantityFallback = "quantity" // legacy alias for product_qty
        static let imageUrl = "image_url"
        static let productUrl = "product_url"
        static let productMetadata = "product_metadata" // per-product metadata
    }

    /// Braze OUTPUT wire property names for the untyped `ecommerce.order_cancelled` /
    /// `ecommerce.order_refunded` custom events. Fixed by the Braze schema, deliberately distinct
    /// from the `Ecommerce` INPUT keys even where names match (e.g. `Ecommerce.totalValue` is
    /// "ecommerce_total_value", `EcommerceWireKeys.totalValue` is "total_value"). Do not assume a
    /// pair sharing a Swift name shares a string value.
    enum EcommerceWireKeys {
        static let currency = "currency"
        static let source = "source"
        static let products = "products"
        static let metadata = "metadata"
        static let quantity = "quantity"
        static let price = "price"
        static let totalValue = "total_value"
        static let subtotalValue = "subtotal_value"
        static let tax = "tax"
        static let shipping = "shipping"
        static let totalDiscounts = "total_discounts"
    }
}

public enum AppboyUserAttribute: String, CaseIterable {
    case firstName = "first_name"
    case lastName = "last_name"
    case email
    case dateOfBirth = "date_of_birth"
    case country
    case language
    case homeCity = "home_city"
    case phone
    case gender
}
