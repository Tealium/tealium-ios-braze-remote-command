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
        case facebookUser = "facebookuser"
        case twitterUser = "twitteruser"
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
        case wipeData = "wipedata"
        
        //        public static final String ENABLE_SDK = "enable_sdk"; // different
//                public static final String WIPE_DATA = "wipe_data"; // different
//                public static final String REGISTER_TOKEN = "registertoken"; // missing
//                public static final String ADD_TO_SUBSCRIPTION_GROUP = "addtosubscriptiongroup"; // missing - different on the tag
//                public static final String REMOVE_FROM_SUBSCRIPTION_GROUP = "removefromsubscriptiongroup"; // missing - different on the tag
    }
    
    enum Keys {
        static let apiKey = "api_key"
        static let launchOptions = "launch_options"
        static let pushToken = "push_token"
//        static let userAttribute = "user_attributes"
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
        static let facebookUser = "facebook_user"
        static let twitterUser = "twitter_user"
        static let enableSDK = "enable_sdk"
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
    }
    
    enum Options {
        static let ABKRequestProcessingPolicyOptionKey = "ABKRequestProcessingPolicyOptionKey"
        static let ABKFlushIntervalOptionKey = "ABKFlushIntervalOptionKey"
        static let ABKEnableAutomaticLocationCollectionKey = "ABKEnableAutomaticLocationCollectionKey"
        static let ABKEnableGeofencesKey = "ABKEnableGeofencesKey"
        static let ABKIDFADelegateKey = "ABKIDFADelegateKey"
        static let ABKEndpointKey = "ABKEndpointKey"
        static let ABKURLDelegateKey = "ABKURLDelegateKey"
        static let ABKSessionTimeoutKey = "ABKSessionTimeoutKey"
        static let ABKMinimumTriggerTimeIntervalKey = "ABKMinimumTriggerTimeIntervalKey"
        static let ABKDeviceWhitelistKey = "ABKDeviceWhitelistKey"
        static let ABKPushStoryAppGroupKey = "ABKPushStoryAppGroupKey"
    }
    
    enum SocialMedia {
//        static let userInfo = "user_info"
        static let friendsCount = "friends_count"
        static let likes = "likes"
        static let userDescription = "description"
        static let twitterName = "twitter_name"
        static let profileImageUrl = "profile_image_url"
        static let screenName = "screen_name"
        static let followersCount = "followers_count"
        static let statusesCount = "statuses_count"
        static let twitterId = "twitter_id"
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
    case avatarImageURL = "avatar_image_url"
    case gender
}

public enum AppboyUserGenderType: Int {
    case male
    case female
    case other
    case unknown
    case notApplicable
    case preferNotToSay

    static func from(_ value: String) -> AppboyUserGenderType {
        let lowercasedGender = value.lowercased()
        if lowercasedGender == "male" {
            return .male
        } else if lowercasedGender == "female" {
            return .female
        } else if lowercasedGender == "other" {
            return .other
        } else if lowercasedGender == "unknown" {
            return .unknown
        } else if lowercasedGender == "notapplicable" || lowercasedGender == "not_applicable" {
            return .notApplicable
        } else {
            return .preferNotToSay
        }
    }
}

public enum AppboyNotificationSubscription: String {
    case optedIn
    case subscribed
    case unsubscribed

    static func from(_ value: String) -> AppboyNotificationSubscription? {
        let lowercasedSubscription = value.lowercased()
        if lowercasedSubscription == "optedin" {
            return .optedIn
        } else if lowercasedSubscription == "subscribed" {
            return .subscribed
        } else if lowercasedSubscription == "unsubscribed" {
            return .unsubscribed
        } else {
            return nil
        }
    }
}
