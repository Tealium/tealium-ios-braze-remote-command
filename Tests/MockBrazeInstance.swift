//
//  MockBrazeInstance.swift
//  TealiumBrazeTests
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation
@testable import TealiumBraze
import BrazeKit

class MockBrazeInstance: BrazeCommand {
    var braze: Braze?
    
    func onReady(_ onReady: @escaping (Braze) -> Void) {
    }

    var initializeBrazeCallCount = 0
    var changeUserCallCount = 0
    var setAuthSignatureCallCount = 0
    var setUserAttributeCallCount = 0
    var logCustomEventCallCount = 0
    var logCustomEventWithPropertiesCallCount = 0
    var addAliasCallCount = 0
    var setCustomAttributeWithKeyCallCount = 0
    var addToCustomAttributeArrayWithKeyCallCount = 0
    var removeFromCustomAttributeArrayWithKeyCallCount = 0
    var unsetCustomAttributeWithKeyCallCount = 0
    var incrementCustomUserAttributeCallCount = 0
    var setEmailNotificationSubscriptionTypeCallCount = 0
    var setPushNotificationSubscriptionTypeCallCount = 0
    var logPurchaseCallCount = 0
    var logPurchaseWithQuantityCallCount = 0
    var logPurchaseWithPropertiesCallCount = 0
    var logPurchaseWithQuantityWithPropertiesCallCount = 0
    var setLastKnownLocationNoAltitudeVerticalAccuracyCallCount = 0
    var setLastKnownLocationWithAltitudeVerticalAccuracyCallCount = 0
    var registerPushTokenCallCount = 0
    var pushAuthorizationCallCount = 0
    var disableCallCount = 0
    var reEnableCallCount = 0
    var wipeDataCallCount = 0
    var flushCallCount = 0
    
    // Appboy Options
    
    func initializeBraze(brazeConfig: Braze.Configuration) {
        initializeBrazeCallCount += 1
    }
    
    
    func changeUser(_ userIdentifier: String, sdkAuthSignature: String?) {
        changeUserCallCount += 1
    }
    
    func setSdkAuthenticationSignature(_ signature: String) {
        setAuthSignatureCallCount += 1
    }
    
    func setUserAttribute(key: AppboyUserAttribute, value: String) {
        setUserAttributeCallCount += 1
    }
    
    func setUserAttributes(_ attributes: [String : Any]) {
        _ = attributes.map { key, value in
            guard let key = AppboyUserAttribute(rawValue: key), let value = value as? String else {
                return
            }
            setUserAttribute(key: key, value: value)
        }
    }
    
    func logCustomEvent(eventName: String) {
        logCustomEventCallCount += 1
    }
    
    func logCustomEvent(_ eventName: String, properties: [String: Any]) {
        logCustomEventWithPropertiesCallCount += 1
    }
    
    func addAlias(_ aliasName: String, label: String) {
        addAliasCallCount += 1
    }
    
    func setCustomAttributes(_ attributes: [String : Any]) {
        _ = attributes.map { attribute in
            guard let value = attribute.value as? AnyHashable else {
                return
            }
            setCustomAttributeWithKey(attribute.key, value: value)
        }
    }
    
    func setCustomAttributeWithKey(_ key: String, value: AnyHashable) {
        setCustomAttributeWithKeyCallCount += 1
    }
    
    func unsetCustomAttributeWithKey(_ key: String) {
        unsetCustomAttributeWithKeyCallCount += 1
    }
    
    func incrementCustomUserAttributes(_ attributes: [String: Int]) {
        attributes.forEach { attribute in
            incrementCustomUserAttribute(attribute.key, by: attribute.value)
        }
    }
    
    func incrementCustomUserAttribute(_ key: String, by: Int) {
        incrementCustomUserAttributeCallCount += 1
    }
    
    func setCustomAttributeArrayWithKey(_ key: String, array: [String]?) {
        setCustomAttributeWithKeyCallCount += 1
    }
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        addToCustomAttributeArrayWithKeyCallCount += 1
    }
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        removeFromCustomAttributeArrayWithKeyCallCount += 1
    }
    
    func setEmailNotificationSubscriptionType(value: Braze.User.SubscriptionState) {
        setEmailNotificationSubscriptionTypeCallCount += 1
    }
    
    func setPushNotificationSubscriptionType(value: Braze.User.SubscriptionState) {
        setPushNotificationSubscriptionTypeCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double) {
        logPurchaseCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int) {
        logPurchaseWithQuantityCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double, properties: [String : Any]?) {
        logPurchaseWithPropertiesCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int, properties: [String : Any]?) {
        logPurchaseWithQuantityWithPropertiesCallCount += 1
    }
    
    func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double) {
        setLastKnownLocationNoAltitudeVerticalAccuracyCallCount += 1
    }

    func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double, altitude: Double, verticalAccuracy: Double) {
        setLastKnownLocationWithAltitudeVerticalAccuracyCallCount += 1
    }
    
    func registerPushToken(_ pushToken: String) {
        registerPushTokenCallCount += 1
    }
    
    func pushAuthorization(fromUserNotificationCenter: Bool) {
        pushAuthorizationCallCount += 1
    }
    
    func enableSDK(_ enabled: Bool) {
        if enabled {
            reEnableCallCount += 1
        } else {
            disableSDK()
        }
    }

    func disableSDK() {
        disableCallCount += 1
    }

    func wipeData() {
        wipeDataCallCount += 1
    }
    
    func flush() {
        flushCallCount += 1
    }
    
    var adTrackingEnabled = false
    func setAdTrackingEnabled(_ enabled: Bool) {
        adTrackingEnabled = enabled
    }
    
    var subscriptionGroups = Set<String>()
    func addToSubscriptionGroup(_ group: String) {
        subscriptionGroups.insert(group)
    }
    
    func removeFromSubscriptionGroup(_ group: String) {
        subscriptionGroups.remove(group)
    }
}
