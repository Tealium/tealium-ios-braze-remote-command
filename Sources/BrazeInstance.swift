//
//  BrazeInstance.swift
//  TealiumBraze
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation

import BrazeKit

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
    func changeUser(_ userIdentifier: String, sdkAuthSignature: String?)
    
    func setSdkAuthenticationSignature(_ signature: String)
    
    func addAlias(_ aliasName: String, label: String)
    
    // MARK: Events
    func logCustomEvent(eventName: String)
    
    func logCustomEvent(_ eventName: String, properties: [String: Any])
    
    func setAdTrackingEnabled(_ enabled: Bool)
    
    func setIdentiferForAdvertiser(_ identifier: String)
    
    func setIdentiferForVendor(_ identifier: String)
    
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
    func setEmailNotificationSubscriptionType(value: Braze.User.SubscriptionState)
    
    func setPushNotificationSubscriptionType(value: Braze.User.SubscriptionState)
    
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
    
    public func changeUser(_ userIdentifier: String, sdkAuthSignature: String?) {
        onReady { braze in
            braze.changeUser(userId: userIdentifier, sdkAuthSignature: sdkAuthSignature)
        }
    }
    
    public func setSdkAuthenticationSignature(_ signature: String) {
        onReady { braze in
            braze.set(sdkAuthenticationSignature: signature)
        }
    }
    
    public func addAlias(_ aliasName: String, label: String) {
        onReady { braze in
            braze.user.add(alias: aliasName, label: label)
        }
    }
    
    public func logCustomEvent(eventName: String) {
        onReady { braze in
            braze.logCustomEvent(name: eventName)
        }
    }
    
    public func logCustomEvent(_ eventName: String, properties: [String: Any]) {
        onReady { braze in
            braze.logCustomEvent(name: eventName, properties: properties)
        }
    }
    
    public func setAdTrackingEnabled(_ enabled: Bool) {
        onReady { braze in
            braze.set(adTrackingEnabled: enabled)
        }
    }
    
    public func setIdentiferForAdvertiser(_ identifier: String) {
        onReady { braze in
            braze.set(identifierForAdvertiser: identifier)
        }
    }
    
    public func setIdentiferForVendor(_ identifier: String) {
        onReady { braze in
            braze.set(identifierForVendor: identifier)
        }
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
        case .lastName:
            braze.user.set(lastName: value)
        case .email:
            braze.user.set(email: value)
        case .dateOfBirth:
            guard let date = DateConverter.shared.iso8601DateFormatter.date(from: value) else {
                return
            }
            braze.user.set(dateOfBirth: date)
        case .country:
            braze.user.set(country: value)
        case .language:
            braze.user.set(language: value)
        case .homeCity:
            braze.user.set(homeCity: value)
        case .phone:
            braze.user.set(phoneNumber: value)
        case .gender:
            braze.user.set(gender: Braze.User.Gender.from(value))
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
        } else if let value = value as? Int {
            braze.user.setCustomAttribute(key: key, value: value)
        } else if let value = value as? Double {
            braze.user.setCustomAttribute(key: key, value: value)
        } else if let value = value as? String {
            braze.user.setCustomAttribute(key: key, value: value)
        } else if let value = value as? Date {
            braze.user.setCustomAttribute(key: key, value: value)
        } else if let value = value as? [String] {
            braze.user.setCustomAttribute(key: key, array: value)
        } else if let value = value as? [String: Any] {
            braze.user.setCustomAttribute(key: key, dictionary: value)
        } else if let value = value as? [[String: Any]] {
            braze.user.setCustomAttribute(key: key, array: value)
        }
    }
    
    public func unsetCustomAttributeWithKey(_ key: String) {
        onReady { braze in
            braze.user.unsetCustomAttribute(key: key)
        }
    }
    
    public func setCustomAttributeArrayWithKey(_ key: String, array: [String]?) {
        onReady { braze in
            braze.user.setCustomAttribute(key: key, array: array)
        }
    }
    
    public func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        onReady { braze in
            braze.user.addToCustomAttributeStringArray(key: key, value: value)
        }
    }
    
    public func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        onReady { braze in
            braze.user.removeFromCustomAttributeStringArray(key: key, value: value)
        }
    }
    
    public func setEmailNotificationSubscriptionType(value: Braze.User.SubscriptionState) {
        onReady { braze in
            braze.user.set(emailSubscriptionState: value)
        }
    }
    
    public func setPushNotificationSubscriptionType(value: Braze.User.SubscriptionState) {
        onReady { braze in
            braze.user.set(pushNotificationSubscriptionState: value)
        }
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
    }
    
    public func setLastKnownLocationWithLatitude(latitude: Double,
                                                 longitude: Double,
                                                 horizontalAccuracy: Double) {
        onReady { braze in
            braze.user.setLastKnownLocation(latitude: latitude,
                                            longitude: longitude,
                                            horizontalAccuracy: horizontalAccuracy)
        }
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
    }
    
    public func wipeData() {
        onReady { braze in
            braze.wipeData()
        }
    }
}
