//
//  BrazeRemoteCommand.swift
//  TealiumBraze
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

public class BrazeRemoteCommand: RemoteCommand {

    let brazeInstance: BrazeCommand?

    public init(brazeInstance: BrazeCommand = BrazeInstance(), type: RemoteCommandType = .webview) {
        self.brazeInstance = brazeInstance
        weak var weakSelf: BrazeRemoteCommand?
        super.init(commandId: BrazeConstants.commandId,
                   description: BrazeConstants.description,
            type: type,
            completion: { response in
                guard let payload = response.payload else {
                    return
                }
                weakSelf?.processRemoteCommand(with: payload)
            })
        weakSelf = self
    }

    func processRemoteCommand(with payload: [String: Any]) {
        guard let brazeInstance = brazeInstance,
              let command = payload[BrazeConstants.commandName] as? String else {
                return
        }
        let commands = command.split(separator: BrazeConstants.separator)
        let brazeCommands = commands.map { command in
            return command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        brazeCommands.forEach {
            let command = BrazeConstants.Commands(rawValue: $0.lowercased())
            switch command {
            case .initialize:
                var appboyOptions = [String: Any]()
                guard let apiKey = payload[BrazeConstants.Keys.apiKey] as? String else {
                    return
                }
                if let requestProcessingPolicy = payload[BrazeConstants.Keys.requestProcessingPolicy] as? Int,
                    let processingPolicy = ABKRequestProcessingPolicy(rawValue: requestProcessingPolicy) {
                    appboyOptions[BrazeConstants.Options.ABKRequestProcessingPolicyOptionKey] = processingPolicy
                }
                if let flushInterval = payload[BrazeConstants.Keys.flushInterval] as? Double {
                    appboyOptions[BrazeConstants.Options.ABKFlushIntervalOptionKey] = TimeInterval(flushInterval)
                }
                if let enableAdvertiserTracking = convertToBool(payload[BrazeConstants.Keys.enableAdvertiserTracking]) {
                    appboyOptions[BrazeConstants.Options.ABKIDFADelegateKey] = enableAdvertiserTracking
                }
                if let enableDeepLinkHandling = convertToBool(payload[BrazeConstants.Keys.enableDeepLinkHandling]) {
                    appboyOptions[BrazeConstants.Options.ABKURLDelegateKey] = enableDeepLinkHandling
                }
                if let deviceOptionsKey = payload[BrazeConstants.Keys.deviceOptions] as? Int {
                    let deviceOptions = ABKDeviceOptions(rawValue: UInt(deviceOptionsKey))
                    appboyOptions[BrazeConstants.Options.ABKDeviceWhitelistKey] = deviceOptions
                }
                if let endpoint = payload[BrazeConstants.Keys.customEndpoint] as? String {
                    appboyOptions[BrazeConstants.Options.ABKEndpointKey] = endpoint
                }
                if let sessionTimeout = payload[BrazeConstants.Keys.sessionTimeout] as? Int {
                    appboyOptions[BrazeConstants.Options.ABKSessionTimeoutKey] = sessionTimeout
                }
                if let disableLocation = convertToBool(payload[BrazeConstants.Keys.disableLocation]) {
                    appboyOptions[BrazeConstants.Options.ABKEnableAutomaticLocationCollectionKey] = !disableLocation
                }
                if let enableGeofences = convertToBool(payload[BrazeConstants.Keys.enableGeofences]) {
                    appboyOptions[BrazeConstants.Options.ABKEnableGeofencesKey] = enableGeofences
                    if enableGeofences {
                        brazeInstance.logSingleLocation()
                    }
                }
                if let triggerInterval = payload[BrazeConstants.Keys.triggerIntervalSeconds] as? Int {
                    appboyOptions[BrazeConstants.Options.ABKMinimumTriggerTimeIntervalKey] = triggerInterval
                } else if let triggerInterval = payload[BrazeConstants.Keys.triggerIntervalSeconds] as? Double {
                    appboyOptions[BrazeConstants.Options.ABKMinimumTriggerTimeIntervalKey] = Int(triggerInterval)
                }
                if let pushStoryIdentifier = payload[BrazeConstants.Keys.pushStoryIdentifier] as? String {
                    appboyOptions[BrazeConstants.Options.ABKPushStoryAppGroupKey] = pushStoryIdentifier
                }
                guard let launchOptions = payload[BrazeConstants.Keys.launchOptions] as? [UIApplication.LaunchOptionsKey: Any] else {
                    return brazeInstance.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: nil, appboyOptions: appboyOptions)
                }
                brazeInstance.initializeBraze(apiKey: apiKey, application: UIApplication.shared, launchOptions: launchOptions, appboyOptions: appboyOptions)
            case .userIdentifier:
                guard let userIdentifier = payload[BrazeConstants.Keys.userIdentifier] as? String else {
                    return
                }
                brazeInstance.changeUser(userIdentifier)
            case .userAlias:
                guard let userAlias = payload[BrazeConstants.Keys.userAlias] as? String,
                      let label = payload[BrazeConstants.Keys.aliasLabel] as? String else {
                    return
                }
                brazeInstance.addAlias(userAlias, label: label)
            case .userAttribute:
                brazeInstance.setUserAttributes(payload)
            case .facebookUser:
                guard var facebookInfo = payload[BrazeConstants.Keys.facebookUser] as? [String: Any] else {
                    return
                }
                if let numberOfFriends = payload[BrazeConstants.SocialMedia.friendsCount] as? Int {
                    facebookInfo[BrazeConstants.SocialMedia.friendsCount] = numberOfFriends
                }
                if let facebookLikes = payload[BrazeConstants.SocialMedia.likes] as? NSArray {
                    facebookInfo[BrazeConstants.SocialMedia.likes] = facebookLikes
                }
                brazeInstance.setFacebookUser(facebookInfo)
            case .twitterUser:
                var twitterInfo = [String: Any]()
                if let userDescription = payload[BrazeConstants.SocialMedia.userDescription] as? String {
                    twitterInfo[BrazeConstants.SocialMedia.userDescription] = userDescription
                }
                if let twitterName = payload[BrazeConstants.SocialMedia.twitterName] as? String {
                    twitterInfo[BrazeConstants.SocialMedia.twitterName] = twitterName
                }
                if let profileImageUrl = payload[BrazeConstants.SocialMedia.profileImageUrl] as? String {
                    twitterInfo[BrazeConstants.SocialMedia.profileImageUrl] = profileImageUrl
                }
                if let screenName = payload[BrazeConstants.SocialMedia.screenName] as? String {
                    twitterInfo[BrazeConstants.SocialMedia.screenName] = screenName
                }
                if let followersCount = payload[BrazeConstants.SocialMedia.followersCount] as? Int {
                    twitterInfo[BrazeConstants.SocialMedia.followersCount] = followersCount
                }
                if let friendsCount = payload[BrazeConstants.SocialMedia.friendsCount] as? Int {
                    twitterInfo[BrazeConstants.SocialMedia.friendsCount] = friendsCount
                }
                if let statusesCount = payload[BrazeConstants.SocialMedia.statusesCount] as? Int {
                    twitterInfo[BrazeConstants.SocialMedia.statusesCount] = statusesCount
                }
                if let twitterId = payload[BrazeConstants.SocialMedia.twitterId] as? Int {
                    twitterInfo[BrazeConstants.SocialMedia.twitterId] = twitterId
                }
                brazeInstance.setTwitterUser(twitterInfo)
            case .logCustomEvent:
                var payload = payload
                guard let eventName = payload[BrazeConstants.Keys.eventName] as? String else {
                    return
                }
                if let eventKeyFromJSON = payload[BrazeConstants.Keys.eventKey] as? [String: Any] {
                    payload[BrazeConstants.Keys.eventProperties] = eventKeyFromJSON
                }
                guard let properties = payload[BrazeConstants.Keys.eventProperties] as? [String: Any] else {
                    return brazeInstance.logCustomEvent(eventName: eventName)
                }
                brazeInstance.logCustomEvent(eventName, properties: properties)
            case .setCustomAttribute:
                guard let attributes = payload[BrazeConstants.Keys.customAttribute] as? [String: Any] else {
                    return
                }
                brazeInstance.setCustomAttributes(attributes)
            case .unsetCustomAttribute:
                guard let attributeKey = payload[BrazeConstants.Keys.unsetCustomAttribute] as? String else {
                    return
                }
                brazeInstance.unsetCustomAttributeWithKey(attributeKey)
            case .incrementCustomAttribute:
                guard let attributes = payload[BrazeConstants.Keys.incrementCustomAttribute] as? [String: Int] else {
                    return
                }
                brazeInstance.incrementCustomUserAttributes(attributes)
            case .setCustomArrayAttribute:
                guard let customAttributes = payload[BrazeConstants.Keys.customArrayAttribute] as? [String: [Any]] else {
                    return
                }
                _ = customAttributes.compactMap { key, value in
                    brazeInstance.setCustomAttributeArrayWithKey(key, array: value)
                }
            case .appendCustomArrayAttribute:
                guard let customAttributes = payload[BrazeConstants.Keys.appendCustomArrayAttribute] as? [String: String] else {
                    return
                }
                _ = customAttributes.map { key, value in
                    brazeInstance.addToCustomAttributeArrayWithKey(key, value: value)
                }
            case .removeCustomArrayAttribute:
                guard let customAttributes = payload[BrazeConstants.Keys.removeCustomArrayAttribute] as? [String: String] else {
                    return
                }
                _ = customAttributes.map { key, value in
                    brazeInstance.removeFromCustomAttributeArrayWithKey(key, value: value)
                }
            case .emailNotification:
                guard let emailNotification = payload[BrazeConstants.Keys.emailNotification] as? String,
                      let subscriptionType = AppboyNotificationSubscription.from(emailNotification) else {
                    return
                }
                brazeInstance.setEmailNotificationSubscriptionType(value: subscriptionType)
            case .pushNotification:
                guard let pushNotification = payload[BrazeConstants.Keys.pushNotification] as? String,
                      let subscriptionType = AppboyNotificationSubscription.from(pushNotification) else {
                    return
                }
                brazeInstance.setPushNotificationSubscriptionType(value: subscriptionType)
            case .logPurchase:
                var payload = payload
                if let purchaseKeyFromJSON = payload[BrazeConstants.Keys.purchaseKey] as? [String: Any] {
                    payload[BrazeConstants.Keys.purchaseProperties] = purchaseKeyFromJSON
                }
                
                guard let productIdentifier = payload[BrazeConstants.Keys.productIdentifier] as? [String],
                    let currency = payload[BrazeConstants.Keys.currency] as? String,
                    let priceDouble = payload[BrazeConstants.Keys.price] as? [Double] else {
                        return
                }
                let prices = priceDouble.map { price in
                    NSDecimalNumber(floatLiteral: price)
                }
                let products = (productId: productIdentifier, price: prices)

                if let quantity = payload[BrazeConstants.Keys.quantity] as? [Int] {
                    let unsignedQty = quantity.map { UInt($0) }
                    let products = (productId: productIdentifier, price: prices, quantity: unsignedQty)
                    if let properties = payload[BrazeConstants.Keys.purchaseProperties] as? [AnyHashable: Any] {
                        for (index, element) in products.productId.enumerated() {
                            return brazeInstance.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index], properties: properties)
                        }
                    }
                    for (index, element) in products.productId.enumerated() {
                        brazeInstance.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index])
                    }
                } else if let properties = payload[BrazeConstants.Keys.purchaseProperties] as? [AnyHashable: Any] {
                    for (index, element) in products.productId.enumerated() {
                        brazeInstance.logPurchase(element, currency: currency, price: products.price[index], properties: properties)
                    }
                } else {
                    for (index, element) in products.productId.enumerated() {
                        brazeInstance.logPurchase(element, currency: currency, price: products.price[index])
                    }
                }
            case .setLastKnownLocation:
                guard let latitude = payload[BrazeConstants.Keys.latitude] as? Double,
                    let longitude = payload[BrazeConstants.Keys.longitude] as? Double,
                    let horizontalAccuracy = payload[BrazeConstants.Keys.horizontalAccuracy] as? Double else {
                        print("""
                                *** Tealium Remote Command Error - Braze: In order to set the user's last known location,
                                you must provide latitude, longitude, and horizontal accuracy.
                              """)
                        return
                }
                guard let altitude = payload[BrazeConstants.Keys.altitude] as? Double,
                    let verticalAccuracy = payload[BrazeConstants.Keys.verticalAccuracy] as? Double else {
                        return brazeInstance.setLastKnownLocationWithLatitude(latitude: latitude,
                                                                                  longitude: longitude,
                                                                                  horizontalAccuracy: horizontalAccuracy)
                }
                brazeInstance.setLastKnownLocationWithLatitude(latitude: latitude,
                                                                          longitude: longitude,
                                                                          horizontalAccuracy: horizontalAccuracy,
                                                                          altitude: altitude,
                                                                          verticalAccuracy: verticalAccuracy)
            case .enableSDK:
                guard let enabled = payload[BrazeConstants.Keys.enableSDK] as? Bool else {
                    return
                }
                brazeInstance.enableSDK(enabled)
            case .wipeData:
                brazeInstance.wipeData()
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
    
    public func convertToBool<T>(_ value: T) -> Bool? {
        if let string = value as? String,
            let bool = Bool(string) {
            return bool
        } else if let int = value as? Int {
            let bool = (int == 1) ? true : false
            return bool
        } else if let bool = value as? Bool {
            return bool
        }
        return nil
    }

}

