//
//  BrazeCommand.swift
//  RemoteCommandModules
//
//  Created by Jonathan Wong on 10/29/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import UIKit
import Appboy_iOS_SDK
#if COCOAPODS
import TealiumSwift
#else
import TealiumCore
import TealiumTagManagement
import TealiumRemoteCommands
#endif


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

public enum SocialMediaKey: String {
    case userInfo = "user_info"
    case friendsCount = "friends_count"
    case likes = "likes"
    case userDescription = "description"
    case twitterName = "twitter_name"
    case profileImageUrl = "profile_image_url"
    case screenName = "screen_name"
    case followersCount = "followers_count"
    case statusesCount = "statuses_count"
    case twitterId = "twitter_id"
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

public class BrazeCommand {
    
    public enum AppboyKey {
        static let command = "command_name"
        static let apiKey = "api_key"
        static let launchOptions = "launch_options"
        static let pushToken = "push_token"
        static let userAttribute = "user_attributes"
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
        static let eventProperties = "event_properties"
        static let eventName = "event_name"
        static let productIdentifier = "product_id"
        static let currency = "order_currency"
        static let price = "product_unit_price"
        static let quantity = "quantity"
        static let purchaseProperties = "purchase_properties"
        static let facebookUser = "facebook_id"
        static let twitterUser = "twitter_user"
        static let enableSDK = "enable_sdk"
        static let sessionTimeout = "session_timeout"
        static let disableLocation = "disable_location"
        static let triggerIntervalSeconds = "trigger_interval_seconds"
    }
    
    public enum AppboyCommand {
        static let initialize = "initialize"
        static let userIdentifier = "useridentifier"
        static let userAlias = "useralias"
        static let userAttribute = "userattribute"
        static let facebookUser = "facebookuser"
        static let twitterUser = "twitteruser"
        static let setCustomAttribute = "setcustomattribute"
        static let unsetCustomAttribute = "unsetcustomattribute"
        static let setCustomArrayAttribute = "setcustomarrayattribute"
        static let appendCustomArrayAttribute = "appendcustomarrayattribute"
        static let removeCustomArrayAttribute = "removecustomarrayattribute"
        static let emailNotification = "emailnotification"
        static let pushNotification = "pushnotification"
        static let incrementCustomAttribute = "incrementcustomattribute"
        static let logCustomEvent = "logcustomevent"
        static let logPurchase = "logpurchase"
        static let enableSDK = "enablesdk"
        static let wipeData = "wipedata"
    }
    
    public enum AppboyOption {
        static let ABKDisableAutomaticLocationCollectionKey = "ABKDisableAutomaticLocationCollectionKey"
        static let ABKSessionTimeoutKey = "ABKSessionTimeoutKey"
        static let ABKMinimumTriggerTimeIntervalKey = "ABKMinimumTriggerTimeIntervalKey"
    }
    
    let brazeTracker: BrazeTrackable
    
    public init(brazeTracker: BrazeTrackable) {
        self.brazeTracker = brazeTracker
    }
    
    public func remoteCommand() -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: "braze", description: "Braze Remote Command") { response in
            let payload = response.payload()
            guard let command = payload[AppboyKey.command] as? String else {
                return
            }
            
            let commands = command.split(separator: ",")
            let brazeCommands = commands.map { command in
                return command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
            self.parseCommands(brazeCommands, payload: payload)
        }
    }
    
    public func parseCommands(_ commands: [String], payload: [String: Any]) {
        commands.forEach { command in
            let lowercasedCommand = command.lowercased()
            switch lowercasedCommand {
            case AppboyCommand.initialize:
                var appboyOptions = [String: Any]()
                guard let apiKey = payload[AppboyKey.apiKey] as? String else {
                    return
                }
                if let sessionTimeout = payload[AppboyKey.sessionTimeout] as? Int {
                    appboyOptions[AppboyOption.ABKSessionTimeoutKey] = sessionTimeout
                }
                if let disableLocation = payload[AppboyKey.disableLocation] as? Bool {
                    appboyOptions[AppboyOption.ABKDisableAutomaticLocationCollectionKey] = disableLocation
                }
                if let triggerInterval = payload[AppboyKey.triggerIntervalSeconds] as? Int {
                    appboyOptions[AppboyOption.ABKMinimumTriggerTimeIntervalKey] = triggerInterval
                }
                guard let launchOptions = payload[AppboyKey.launchOptions] as? [UIApplication.LaunchOptionsKey: Any] else {
                    return self.brazeTracker.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: nil, appboyOptions: appboyOptions)
                }
                self.brazeTracker.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: launchOptions, appboyOptions: appboyOptions)
            case AppboyCommand.userIdentifier:
                guard let userIdentifier = payload[AppboyKey.userIdentifier] as? String else {
                    return
                }
                self.brazeTracker.changeUser(userIdentifier)
            case AppboyCommand.userAlias:
                guard let userAlias = payload[AppboyKey.userAlias] as? String, let label = payload[AppboyKey.aliasLabel] as? String else {
                    return
                }
                self.brazeTracker.addAlias(userAlias, label: label)
            case AppboyCommand.userAttribute:
                self.brazeTracker.setUserAttributes(payload)
            case AppboyCommand.facebookUser:
                guard var facebookInfo = payload[AppboyKey.facebookUser] as? [String: Any] else {
                    return
                }
                if let numberOfFriends = payload[SocialMediaKey.friendsCount.rawValue] as? Int {
                    facebookInfo[SocialMediaKey.friendsCount.rawValue] = numberOfFriends
                }
                if let facebookLikes = payload[SocialMediaKey.likes.rawValue] as? NSArray {
                    facebookInfo[SocialMediaKey.likes.rawValue] = facebookLikes
                }
                self.brazeTracker.setFacebookUser(facebookInfo)
            case AppboyCommand.twitterUser:
                var twitterInfo = [String: Any]()
                if let userDescription = payload[SocialMediaKey.userDescription.rawValue] as? String {
                    twitterInfo[SocialMediaKey.userDescription.rawValue] = userDescription
                }
                if let twitterName = payload[SocialMediaKey.twitterName.rawValue] as? String {
                    twitterInfo[SocialMediaKey.twitterName.rawValue] = twitterName
                }
                if let profileImageUrl = payload[SocialMediaKey.profileImageUrl.rawValue] as? String {
                    twitterInfo[SocialMediaKey.profileImageUrl.rawValue] = profileImageUrl
                }
                if let screenName = payload[SocialMediaKey.screenName.rawValue] as? String {
                    twitterInfo[SocialMediaKey.screenName.rawValue] = screenName
                }
                if let followersCount = payload[SocialMediaKey.followersCount.rawValue] as? Int {
                    twitterInfo[SocialMediaKey.followersCount.rawValue] = followersCount
                }
                if let friendsCount = payload[SocialMediaKey.friendsCount.rawValue] as? Int {
                    twitterInfo[SocialMediaKey.friendsCount.rawValue] = friendsCount
                }
                if let statusesCount = payload[SocialMediaKey.statusesCount.rawValue] as? Int {
                    twitterInfo[SocialMediaKey.statusesCount.rawValue] = statusesCount
                }
                if let twitterId = payload[SocialMediaKey.twitterId.rawValue] as? Int {
                    twitterInfo[SocialMediaKey.twitterId.rawValue] = twitterId
                }
                self.brazeTracker.setTwitterUser(twitterInfo)
            case AppboyCommand.logCustomEvent:
                guard let eventName = payload[AppboyKey.eventName] as? String else {
                    return
                }
                guard let properties = payload[AppboyKey.eventProperties] as? [String: Any] else {
                    return self.brazeTracker.logCustomEvent(eventName: eventName)
                }
                self.brazeTracker.logCustomEvent(eventName, properties: properties)
            case AppboyCommand.setCustomAttribute:
                guard let attributes = payload[AppboyKey.customAttribute] as? [String: Any] else {
                    return
                }
                self.brazeTracker.setCustomAttributes(attributes)
            case AppboyCommand.unsetCustomAttribute:
                guard let attributeKey = payload[AppboyKey.unsetCustomAttribute] as? String else {
                    return
                }
                self.brazeTracker.unsetCustomAttributeWithKey(attributeKey)
            case AppboyCommand.incrementCustomAttribute:
                guard let attributes = payload[AppboyKey.incrementCustomAttribute] as? [String: Int] else {
                    return
                }
                self.brazeTracker.incrementCustomUserAttributes(attributes)
            case AppboyCommand.setCustomArrayAttribute:
                guard let customAttributes = payload[AppboyKey.customArrayAttribute] as? [String: [Any]] else {
                    return
                }
                _ = customAttributes.compactMap { key, value in
                    self.brazeTracker.setCustomAttributeArrayWithKey(key, array: value)
                }
            case AppboyCommand.appendCustomArrayAttribute:
                guard let customAttributes = payload[AppboyKey.appendCustomArrayAttribute] as? [String: String] else {
                    return
                }
                _ = customAttributes.map { key, value in
                    self.brazeTracker.addToCustomAttributeArrayWithKey(key, value: value)
                }
            case AppboyCommand.removeCustomArrayAttribute:
                guard let customAttributes = payload[AppboyKey.removeCustomArrayAttribute] as? [String: String] else {
                    return
                }
                _ = customAttributes.map { key, value in
                    self.brazeTracker.removeFromCustomAttributeArrayWithKey(key, value: value)
                }
            case AppboyCommand.emailNotification:
                guard let emailNotification = payload[AppboyKey.emailNotification] as? String, let subscriptionType = AppboyNotificationSubscription.from(emailNotification) else {
                    return
                }
                self.brazeTracker.setEmailNotificationSubscriptionType(value: subscriptionType)
            case AppboyCommand.pushNotification:
                guard let pushNotification = payload[AppboyKey.pushNotification] as? String, let subscriptionType = AppboyNotificationSubscription.from(pushNotification) else {
                    return
                }
                self.brazeTracker.setPushNotificationSubscriptionType(value: subscriptionType)
            case AppboyCommand.logPurchase:
                guard let productIdentifier = payload[AppboyKey.productIdentifier] as? [String],
                    let currency = payload[AppboyKey.currency] as? String,
                    let priceDouble = payload[AppboyKey.price] as? [Double] else {
                        return
                }
                let prices = priceDouble.map { price in
                    NSDecimalNumber(floatLiteral: price) 
                }
                let products = (productId: productIdentifier, price: prices)
                
                if let quantity = payload[AppboyKey.quantity] as? [Int] {
                    let unsignedQty = quantity.map { UInt($0) }
                    let products = (productId: productIdentifier, price: prices, quantity: unsignedQty)
                    if let properties = payload[AppboyKey.purchaseProperties] as? [AnyHashable: Any] {
                        for (index, element) in products.productId.enumerated() {
                            return self.brazeTracker.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index], properties: properties)
                        }
                    }
                    for (index, element) in products.productId.enumerated() {
                        return self.brazeTracker.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index])
                    }
                } else if let properties = payload[AppboyKey.purchaseProperties] as? [AnyHashable: Any] {
                    for (index, element) in products.productId.enumerated() {
                        self.brazeTracker.logPurchase(element, currency: currency, price: products.price[index], properties: properties)
                    }
                } else {
                    for (index, element) in products.productId.enumerated() {
                        self.brazeTracker.logPurchase(element, currency: currency, price: products.price[index])
                    }
                }
            case AppboyCommand.enableSDK:
                guard let enabled = payload[AppboyKey.enableSDK] as? Bool else {
                    return
                }
                self.brazeTracker.enableSDK(enabled)
            case AppboyCommand.wipeData:
                self.brazeTracker.wipeData()
            default:
                break
            }
        }
    }
    
    public func setUserAttribute(value: AppboyUserGenderType) {
        // currently only one int type
        var gender: ABKUserGenderType
        switch value {
        case .male:
            gender = ABKUserGenderType.male
        case .female:
            gender = ABKUserGenderType.female
        case .other:
            gender = ABKUserGenderType.other
        case .unknown:
            gender = ABKUserGenderType.unknown
        case .notApplicable:
            gender = ABKUserGenderType.notApplicable
        case .preferNotToSay:
            gender = ABKUserGenderType.preferNotToSay
        }
        
        Appboy.sharedInstance()?.user.setGender(gender)
    }
    
}
