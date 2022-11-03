//
//  BrazeInstance.swift
//  TealiumBraze
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
    import AppboyUI
#else
    import Appboy_iOS_SDK
    import BrazeKit
#endif

#if COCOAPODS
import TealiumSwift
#else
import TealiumCore
import TealiumRemoteCommands
#endif

public protocol BrazeCommand {
    
    var braze: Braze? { get }
    
    func onReady(_ onReady: @escaping (Braze) -> Void)

    func flush()
    
    // MARK: Initialization
    func initializeBraze(brazeConfig: Braze.Configuration)
    
    // MARK: User IDs
    func changeUser(_ userIdentifier: String)
    
    func addAlias(_ aliasName: String, label: String)
    
    // MARK: Events
    func logCustomEvent(eventName: String)
    
    func logCustomEvent(_ eventName: String, properties: [String: Any])
    
    // MARK: Attributes
    
    func setUserAttributes(_ attributes: [String: Any])
    
    func setCustomAttributes(_ attributes: [String: Any])
    
    func unsetCustomAttributeWithKey(_ key: String)
    
    func incrementCustomUserAttributes(_ attributes: [String: Int])
    
    // MARK: Array Attributes
    func setCustomAttributeArrayWithKey(_ key: String, array: [String]?)
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String)
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String)
    
    // MARK: Subscriptions
    func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    func addToSubscriptionGroup(_ group: String)
    
    func removeFromSubscriptionGroup(_ group: String)
    
    // MARK: Purchases
    func logPurchase(_ productIdentifier: String, currency: String, price: Double)
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: Double,
                     properties: [String: Any]?)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: Double,
                     quantity: Int,
                     properties: [String: Any]?)
    
    // MARK: Location
    func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double)

    func setLastKnownLocationWithLatitude(latitude: Double,
                                          longitude: Double,
                                          horizontalAccuracy: Double,
                                          altitude: Double,
                                          verticalAccuracy: Double)
    
    // MARK: Enabling/Wiping
    func enableSDK(_ enable: Bool)
    
    func wipeData()
}

public class BrazeInstance: BrazeCommand {
    public var braze: Braze? {
        _onReady.last()
    }
    
    private var _onReady = TealiumReplaySubject<Braze>(cacheSize: 1)

    public init() { }
    
    public func initializeBraze(brazeConfig: Braze.Configuration) {
        let braze = Braze(configuration: brazeConfig)
        _onReady.publish(braze)
    }
    
    public func onReady(_ onReady: @escaping (Braze) -> Void) {
        _onReady.subscribeOnce(onReady)
    }
    
    public func changeUser(_ userIdentifier: String) {
        onReady { braze in
            braze.changeUser(userId: userIdentifier, sdkAuthSignature: nil) // TODO: sdkAuthSignature
        }
//        Appboy.sharedInstance()?.changeUser(userIdentifier)
    }
    
    public func addAlias(_ aliasName: String, label: String) {
        onReady { braze in
            braze.user.add(alias: aliasName, label: label)
        }
//        Appboy.sharedInstance()?.user.addAlias(aliasName, withLabel: label)
    }
    
    public func logCustomEvent(eventName: String) {
        onReady { braze in
            braze.logCustomEvent(name: eventName)
        }
//        Appboy.sharedInstance()?.logCustomEvent(eventName)
    }
    
    public func logCustomEvent(_ eventName: String, properties: [String: Any]) {
        onReady { braze in
            braze.logCustomEvent(name: eventName, properties: properties)
        }
//        Appboy.sharedInstance()?.logCustomEvent(eventName, withProperties: properties)
    }
    
    public func setUserAttributes(_ attributes: [String : Any]) {
        onReady { braze in
            AppboyUserAttribute.allCases.forEach {
                guard let value = attributes["\($0.rawValue)"] as? String else {
                    return
                }
                BrazeInstance.setUserAttribute(braze, key: $0, value: value)
            }
        }
    }
    
    static private func setUserAttribute(_ braze: Braze, key: AppboyUserAttribute, value: String) {
        switch key {
        case .firstName:
            braze.user.set(firstName: value)
//            Appboy.sharedInstance()?.user.firstName = value
        case .lastName:
            braze.user.set(lastName: value)
//            Appboy.sharedInstance()?.user.lastName = value
        case .email:
            braze.user.set(email: value)
//            Appboy.sharedInstance()?.user.email = value
        case .dateOfBirth:
            guard let date = DateConverter.shared.iso8601DateFormatter.date(from: value) else {
                return
            }
            braze.user.set(dateOfBirth: date)
//            Appboy.sharedInstance()?.user.dateOfBirth = date
        case .country:
            braze.user.set(country: value)
//            Appboy.sharedInstance()?.user.country = value
        case .language:
            braze.user.set(language: value)
//            Appboy.sharedInstance()?.user.language = value
        case .homeCity:
            braze.user.set(homeCity: value)
//            Appboy.sharedInstance()?.user.homeCity = value
        case .phone:
            braze.user.set(phoneNumber: value)
//            Appboy.sharedInstance()?.user.phone = value
        case .gender:
            guard let type = AppboyUserGenderType(rawValue: 1), // TODO: type has changed to string!
                let gender = Braze.User.Gender(rawValue: "\(type.rawValue)") else {
                return
            }
            braze.user.set(gender: gender)
//            Appboy.sharedInstance()?.user.setGender(gender)
        }
    }
    
    public func setCustomAttributes(_ attributes: [String : Any]) {
        onReady {  braze in
            attributes.forEach { attribute in
                guard let value = attribute.value as? AnyHashable else {
                    return
                }
                BrazeInstance.setCustomAttribute(braze, withKey: attribute.key, value: value)
            }
        }
    }
    
    static private func setCustomAttribute(_ braze: Braze, withKey key: String, value: AnyHashable) {
        if let value = value as? Bool {
            braze.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andBOOLValue: value)
        } else if let value = value as? Int {
            braze.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andIntegerValue: value)
        } else if let value = value as? Double {
            braze.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDoubleValue: value)
        } else if let value = value as? String {
            braze.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andStringValue: value)
        } else if let value = value as? Date {
            braze.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDateValue: value)
        }
    }
    
    public func unsetCustomAttributeWithKey(_ key: String) {
        onReady { braze in
            braze.user.unsetCustomAttribute(key: key)
        }
//        Appboy.sharedInstance()?.user.unsetCustomAttribute(withKey: key)
    }
    
    public func setCustomAttributeArrayWithKey(_ key: String, array: [String]?) {
        onReady { braze in
            braze.user.setCustomAttributeArray(key: key, array: array)
        }
//        Appboy.sharedInstance()?.user.setCustomAttributeArrayWithKey(key, array: array)
    }
    
    public func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        onReady { braze in
            braze.user.addToCustomAttributeArray(key: key, value: value)
        }
//        Appboy.sharedInstance()?.user.addToCustomAttributeArray(withKey: key, value: value)
    }
    
    public func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        onReady { braze in
            braze.user.removeFromCustomAttributeArray(key: key, value: value)
        }
//        Appboy.sharedInstance()?.user.removeFromCustomAttributeArray(withKey: key, value: value)
    }
    
    public func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        onReady { braze in
            braze.user.set(emailSubscriptionState: value.brazeSubscriptionState)
        }
//            switch value {
//            case .optedIn:
//                //            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.optedIn)
//            case .subscribed:
//                //            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.subscribed)
//            case .unsubscribed:
//                //            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.unsubscribed)
//            }
    }
    
    public func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        onReady { braze in
            braze.user.set(pushNotificationSubscriptionState: value.brazeSubscriptionState)
        }
//        switch value {
//        case .optedIn:
//            braze?.user.set(pushNotificationSubscriptionState: .optedIn)
////            Appboy.sharedInstance()?.user.setPush(.optedIn)
//        case .subscribed:
//            braze?.user.set(pushNotificationSubscriptionState: .subscribed)
////            Appboy.sharedInstance()?.user.setPush(.subscribed)
//        case .unsubscribed:
//            braze?.user.set(pushNotificationSubscriptionState: .unsubscribed)
////            Appboy.sharedInstance()?.user.setPush(.unsubscribed)
//        }
    }

    public func incrementCustomUserAttributes(_ attributes: [String: Int]) {
        onReady { braze in
            attributes.forEach { attribute in
                braze.user.incrementCustomUserAttribute(key: attribute.key, by: attribute.value)
            }
        }
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: Double) {
        onReady { braze in
            braze.logPurchase(productId: productIdentifier, currency: currency, price: price)
        }
//        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price)
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int) {
        onReady { braze in
            braze.logPurchase(productId: productIdentifier,
                              currency: currency,
                              price: price,
                              quantity: quantity)
        }
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: Double,
                            properties: [String: Any]?) {
        onReady { braze in
            braze.logPurchase(productId: productIdentifier,
                              currency: currency,
                              price: price,
                              properties: properties)
        }
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: Double,
                            quantity: Int,
                            properties: [String: Any]?) {
        onReady { braze in
            braze.logPurchase(productId: productIdentifier,
                              currency: currency,
                              price: price,
                              quantity: quantity,
                              properties: properties)
        }
//        Appboy.sharedInstance()?.logPurchase(productIdentifier,
//                                             inCurrency: currency,
//                                             atPrice: price,
//                                             withQuantity: quantity,
//                                             andProperties: properties)
    }
    
    public func setLastKnownLocationWithLatitude(latitude: Double,
                                                 longitude: Double,
                                                 horizontalAccuracy: Double) {
        onReady { braze in
            braze.user.setLastKnownLocation(latitude: latitude,
                                            longitude: longitude,
                                            horizontalAccuracy: horizontalAccuracy)
        }
//        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy)
    }

    public func setLastKnownLocationWithLatitude(latitude: Double,
                                                 longitude: Double,
                                                 horizontalAccuracy: Double,
                                                 altitude: Double,
                                                 verticalAccuracy: Double) {
        onReady { braze in
            braze.user.setLastKnownLocation(latitude: latitude,
                                            longitude: longitude,
                                            altitude: altitude,
                                            horizontalAccuracy: horizontalAccuracy,
                                            verticalAccuracy: verticalAccuracy)
        }
//        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude,
//                                                                       longitude: longitude,
//                                                                       horizontalAccuracy: horizontalAccuracy,
//                                                                       altitude: altitude,
//                                                                       verticalAccuracy: verticalAccuracy)
    }
    
    public func flush() {
        onReady { braze in
            braze.requestImmediateDataFlush()
        }
    }
    
    public func addToSubscriptionGroup(_ group: String) {
        onReady { braze in
            braze.user.addToSubscriptionGroup(id: group)
        }
    }
    
    public func removeFromSubscriptionGroup(_ group: String) {
        onReady { braze in
            braze.user.removeFromSubscriptionGroup(id: group)
        }
    }
    
    public func enableSDK(_ enable: Bool) {
        onReady { braze in
            braze.enabled = enable
        }
//        if enable {
//            Appboy.requestEnableSDKOnNextAppRun()
//        } else {
//            Appboy.disableSDK()
//        }
    }
    
    public func wipeData() {
        onReady { braze in
            braze.wipeData()
        }
//        Appboy.wipeDataAndDisableForAppRun()
    }
}

extension AppboyNotificationSubscription {
    var brazeSubscriptionState: Braze.User.SubscriptionState {
        switch self {
        case .optedIn: return .optedIn
        case .subscribed: return .subscribed
        case .unsubscribed: return .unsubscribed
        }
    }
}
