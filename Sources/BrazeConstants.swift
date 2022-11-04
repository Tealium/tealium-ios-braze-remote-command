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
    static let version = "2.1.0"
    
    enum Commands: String {
        case initialize = "initialize"
        case userIdentifier = "useridentifier"
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
        static let launchOptions = "launch_options"
        static let isSdkAuthEnabled = "is_sdk_authentication_enabled"
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
        static let productIdentifier = "product_id"
        static let currency = "order_currency"
        static let price = "product_unit_price"
        static let quantity = "quantity"
        static let purchaseKey = "purchase"
        static let purchaseProperties = "purchase_properties"
        static let sessionTimeout = "session_timeout"
        static let disableLocation = "disable_location"
        static let enableGeofences = "enable_geofences"
        static let triggerIntervalSeconds = "trigger_interval_seconds"
        static let latitude = "location_latitude"
        static let longitude = "location_longitude"
        static let horizontalAccuracy = "location_horizontal_accuracy"
        static let altitude = "location_altitude"
        static let verticalAccuracy = "location_vertical_accuracy"
        static let requestProcessingPolicy = "request_processing_policy"
        static let flushInterval = "flush_interval"
        static let enableAdvertiserTracking = "enable_advertiser_tracking"
        static let enableDeepLinkHandling = "enable_deep_link_handling"
        static let customEndpoint = "custom_endpoint"
        static let deviceOptions = "device_options"
        static let pushStoryIdentifier = "push_story_identifier"
        static let subscriptionGroupId = "subscription_group_id"
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
