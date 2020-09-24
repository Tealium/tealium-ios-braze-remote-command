//
//  MockBrazeTracker.swift
//  TealiumBrazeTests
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation
@testable import TealiumBraze

class MockBrazeTracker: BrazeTrackable {

    var initializeBrazeCallCount = 0
    var logSingleLocationCallCount = 0
    var changeUserCallCount = 0
    var setUserAttributeCallCount = 0
    var facebookUserCallCount = 0
    var twitterUserCallCount = 0
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
    
    // Appboy Options
    var appBoyOptionsCount = ["ABKRequestProcessingPolicyOptionKey": 0,
                              "ABKFlushIntervalOptionKey": 0,
                              "ABKIDFADelegateKey": 0,
                              "ABKURLDelegateKey": 0,
                              "ABKDeviceWhitelistKey": 0,
                              "ABKEndpointKey": 0,
                              "ABKSessionTimeoutKey": 0,
                              "ABKEnableAutomaticLocationCollectionKey": 0,
                              "ABKEnableGeofencesKey": 0,
                              "ABKMinimumTriggerTimeIntervalKey": 0,
                              "ABKPushStoryAppGroupKey": 0]
    
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?) {
        initializeBrazeCallCount += 1
    }
    
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?) {
        initializeBrazeCallCount += 1
        
        guard let options = appboyOptions as? [String: Any] else { return }
        
        options.compactMapValues { _ in }.forEach {
            switch $0.key {
            case "ABKRequestProcessingPolicyOptionKey":
                appBoyOptionsCount["ABKRequestProcessingPolicyOptionKey"]! += 1
                case "ABKFlushIntervalOptionKey":
                appBoyOptionsCount["ABKFlushIntervalOptionKey"]! += 1
                case "ABKIDFADelegateKey":
                appBoyOptionsCount["ABKIDFADelegateKey"]! += 1
                case "ABKURLDelegateKey":
                appBoyOptionsCount["ABKURLDelegateKey"]! += 1
                case "ABKEndpointKey":
                appBoyOptionsCount["ABKEndpointKey"]! += 1
                case "ABKSessionTimeoutKey":
                appBoyOptionsCount["ABKSessionTimeoutKey"]! += 1
                case "ABKEnableAutomaticLocationCollectionKey":
                appBoyOptionsCount["ABKEnableAutomaticLocationCollectionKey"]! += 1
                case "ABKEnableGeofencesKey":
                appBoyOptionsCount["ABKEnableGeofencesKey"]! += 1
                case "ABKMinimumTriggerTimeIntervalKey":
                appBoyOptionsCount["ABKMinimumTriggerTimeIntervalKey"]! += 1
                case "ABKPushStoryAppGroupKey":
                appBoyOptionsCount["ABKPushStoryAppGroupKey"]! += 1
                case "ABKDeviceWhitelistKey":
                appBoyOptionsCount["ABKDeviceWhitelistKey"]! += 1
                default:
                    break
            }
        }
    }
    
    func logSingleLocation() {
        logSingleLocationCallCount += 1
    }
    
    func changeUser(_ userIdentifier: String) {
        changeUserCallCount += 1
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
    
    func setFacebookUser(_ user: [String : Any]) {
        facebookUserCallCount += 1
    }
    
    func setTwitterUser(_ user: [String : Any]) {
        twitterUserCallCount += 1
    }
    
    func logCustomEvent(eventName: String) {
        logCustomEventCallCount += 1
    }
    
    func logCustomEvent(_ eventName: String, properties: [AnyHashable: Any]) {
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
    
    func setCustomAttributeArrayWithKey(_ key: String, array: [Any]?) {
        setCustomAttributeWithKeyCallCount += 1
    }
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        addToCustomAttributeArrayWithKeyCallCount += 1
    }
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        removeFromCustomAttributeArrayWithKeyCallCount += 1
    }
    
    func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        setEmailNotificationSubscriptionTypeCallCount += 1
    }
    
    func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        setPushNotificationSubscriptionTypeCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber) {
        logPurchaseCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt) {
        logPurchaseWithQuantityCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, properties: [AnyHashable : Any]?) {
        logPurchaseWithPropertiesCallCount += 1
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt, properties: [AnyHashable : Any]?) {
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
    
}
