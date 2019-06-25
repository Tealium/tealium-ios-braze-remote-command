//
//  BrazeCommand.swift
//  RemoteCommandModules
//
//  Created by Jonathan Wong on 10/29/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import UIKit
import TealiumSwift
import Appboy_iOS_SDK

enum AppboyUserAttribute: String, CaseIterable {
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

enum AppboyUserGenderType: Int {
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

enum SocialMediaKey: String {
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

enum AppboyNotificationSubscription: String {
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

class BrazeCommand {
    
    enum AppboyKey {
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
        static let price = "price"
        static let quantity = "quantity"
        static let purchaseProperties = "purchase_properties"
        static let facebookUser = "facebook_id"
        static let twitterUser = "twitter_user"
    }
    
    enum AppboyCommand {
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
    }
    
    enum AppboyOption {
        static let ABKRequestProcessingPolicyOptionKey = "ABKRequestProcessingPolicyOptionKey"
        static let ABKFlushIntervalOptionKey = "ABKFlushIntervalOptionKey"
        static let ABKDisableAutomaticLocationCollectionKey = "ABKDisableAutomaticLocationCollectionKey"
        static let ABKIDFADelegateKey = "ABKIDFADelegateKey"
        static let ABKAppboyEndpointDelegateKey = "ABKAppboyEndpointDelegateKey"
        static let ABKURLDelegateKey = "ABKURLDelegateKey"
        static let ABKInAppMessageControllerDelegateKey = "ABKInAppMessageControllerDelegateKey"
        static let ABKSessionTimeoutKey = "ABKSessionTimeoutKey"
        static let ABKMinimumTriggerTimeIntervalKey = "ABKMinimumTriggerTimeIntervalKey"
        static let ABKSDKFlavorKey = "ABKSDKFlavorKey"
        static let ABKDeviceWhitelistKey = "ABKDeviceWhitelistKey"
        static let ABKPushStoryAppGroupKey = "ABKPushStoryAppGroupKey"
    }
    
    enum AppboyRequestProcessingPolicy: Int {
        case ABKAutomaticRequestProcessing
        case ABKAutomaticRequestProcessingExceptForDataFlush
        case ABKManualRequestProcessing
    }
    
    enum AppboyFeedbackSentResult: Int {
        case ABKInvalidFeedback
        case ABKNetworkIssue
        case ABKFeedbackSentSuccessfully
    }
    
    struct ABKDeviceOptions: OptionSet {
        let rawValue: Int
        
        static let ABKDeviceOptionNone = ABKDeviceOptions(rawValue: 0)
        static let ABKDeviceOptionResolution = ABKDeviceOptions(rawValue: 1 << 0)
        static let ABKDeviceOptionCarrier = ABKDeviceOptions(rawValue: 1 << 1)
        static let ABKDeviceOptionLocale = ABKDeviceOptions(rawValue: 1 << 2)
        static let ABKDeviceOptionModel = ABKDeviceOptions(rawValue: 1 << 3)
        static let ABKDeviceOptionOSVersion = ABKDeviceOptions(rawValue: 1 << 4)
        static let ABKDeviceOptionIDFV = ABKDeviceOptions(rawValue: 1 << 5)
        static let ABKDeviceOptionIDFA = ABKDeviceOptions(rawValue: 1 << 6)
        static let ABKDeviceOptionPushEnabled = ABKDeviceOptions(rawValue: 1 << 7)
        static let ABKDeviceOptionTimezone = ABKDeviceOptions(rawValue: 1 << 8)
        static let ABKDeviceOptionPushAuthStatus = ABKDeviceOptions(rawValue: 1 << 9)
        static let ABKDeviceOptionAdTrackingEnabled = ABKDeviceOptions(rawValue: 1 << 10)
        static let ABKDeviceOptionAll = ABKDeviceOptions(rawValue: ~0)
    }
    
    let brazeCommandRunner: BrazeCommandRunnable
    
    init(brazeCommandRunner: BrazeCommandRunnable) {
        self.brazeCommandRunner = brazeCommandRunner
    }
    
    /// Parses the remote command
    func remoteCommand() -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: "braze", description: "Braze Remote Command") { response in
            let payload = response.payload()
            guard let command = payload[TealiumRemoteCommand.commandName] as? String else {
                return
            }
            
            let commands = command.split(separator: ",")
            let brazeCommands = commands.map { command in
                return command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
            brazeCommands.forEach { command in
                let lowercasedCommand = command.lowercased()
                switch lowercasedCommand {
                case AppboyCommand.initialize:
                    guard let apiKey = payload[TealiumRemoteCommand.apiKey] as? String else {
                        return
                    }
                    guard let launchOptions = payload[AppboyKey.launchOptions] as? [UIApplication.LaunchOptionsKey: Any] else {
                        return self.brazeCommandRunner.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: nil)
                    }
                    self.brazeCommandRunner.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: launchOptions)
                case AppboyCommand.userIdentifier:
                    guard let userIdentifier = payload[AppboyKey.userIdentifier] as? String else {
                        return
                    }
                    self.brazeCommandRunner.changeUser(userIdentifier)
                case AppboyCommand.userAlias:
                    guard let userAlias = payload[AppboyKey.userAlias] as? String, let label = payload[AppboyKey.aliasLabel] as? String else {
                        return
                    }
                    self.brazeCommandRunner.addAlias(userAlias, label: label)
                case AppboyCommand.userAttribute:
                    self.brazeCommandRunner.setUserAttributes(payload)
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
                    self.brazeCommandRunner.setFacebookUser(facebookInfo)
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
                    self.brazeCommandRunner.setTwitterUser(twitterInfo)
                case AppboyCommand.logCustomEvent:
                    guard let eventName = payload[AppboyKey.eventName] as? String else {
                        return
                    }
                    guard let properties = payload[AppboyKey.eventProperties] as? [String: Any] else {
                        return self.brazeCommandRunner.logCustomEvent(eventName: eventName)
                    }
                    self.brazeCommandRunner.logCustomEvent(eventName, properties: properties)
                case AppboyCommand.setCustomAttribute:
                    guard let attributes = payload[AppboyKey.customAttribute] as? [String: Any] else {
                        return
                    }
                    self.brazeCommandRunner.setCustomAttributes(attributes)
                case AppboyCommand.unsetCustomAttribute:
                    guard let attributeKey = payload[AppboyKey.unsetCustomAttribute] as? String else {
                        return
                    }
                    self.brazeCommandRunner.unsetCustomAttributeWithKey(attributeKey)
                case AppboyCommand.incrementCustomAttribute:
                    guard let attributes = payload[AppboyKey.incrementCustomAttribute] as? [String: Int] else {
                        return
                    }
                    self.brazeCommandRunner.incrementCustomUserAttributes(attributes)
                case AppboyCommand.setCustomArrayAttribute:
                    guard let customAttributes = payload[AppboyKey.customArrayAttribute] as? [String: [Any]] else {
                        return
                    }
                    _ = customAttributes.compactMap { key, value in
                        self.brazeCommandRunner.setCustomAttributeArrayWithKey(key, array: value)
                    }
                case AppboyCommand.appendCustomArrayAttribute:
                    guard let customAttributes = payload[AppboyKey.appendCustomArrayAttribute] as? [String: String] else {
                        return
                    }
                    _ = customAttributes.map { key, value in
                        self.brazeCommandRunner.addToCustomAttributeArrayWithKey(key, value: value)
                    }
                case AppboyCommand.removeCustomArrayAttribute:
                    guard let customAttributes = payload[AppboyKey.removeCustomArrayAttribute] as? [String: String] else {
                        return
                    }
                    _ = customAttributes.map { key, value in
                        self.brazeCommandRunner.removeFromCustomAttributeArrayWithKey(key, value: value)
                    }
                case AppboyCommand.emailNotification:
                    guard let emailNotification = payload[AppboyKey.emailNotification] as? String, let subscriptionType = AppboyNotificationSubscription.from(emailNotification) else {
                        return
                    }
                    self.brazeCommandRunner.setEmailNotificationSubscriptionType(value: subscriptionType)
                case AppboyCommand.pushNotification:
                    guard let pushNotification = payload[AppboyKey.pushNotification] as? String, let subscriptionType = AppboyNotificationSubscription.from(pushNotification) else {
                        return
                    }
                    self.brazeCommandRunner.setPushNotificationSubscriptionType(value: subscriptionType)
                case AppboyCommand.logPurchase:
                    guard let productIdentifier = payload[AppboyKey.productIdentifier] as? String,
                        let currency = payload[AppboyKey.currency] as? String, let priceDouble = payload[AppboyKey.price] as? Double else {
                        return
                    }
                    let price = NSDecimalNumber(floatLiteral: priceDouble)
                    if let quantity = payload[AppboyKey.quantity] as? UInt {
                        if let properties = payload[AppboyKey.purchaseProperties] as? [AnyHashable: Any] {
                            return self.brazeCommandRunner.logPurchase(productIdentifier, currency: currency, price: price, quantity: quantity, properties: properties)
                        }
                        self.brazeCommandRunner.logPurchase(productIdentifier, currency: currency, price: price, quantity: quantity)
                    } else if let properties = payload[AppboyKey.purchaseProperties] as? [AnyHashable: Any] {
                        self.brazeCommandRunner.logPurchase(productIdentifier, currency: currency, price: price, properties: properties)
                    } else {
                        self.brazeCommandRunner.logPurchase(productIdentifier, currency: currency, price: price)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func setUserAttribute(value: AppboyUserGenderType) {
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

extension TealiumRemoteCommand {
    static let commandName = "command"
    static let apiKey = "api_key"
}

