//
//  BrazeRemoteCommand.swift
//  TealiumBraze
//
//  Created by Jonathan Wong on 10/29/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import UIKit

import BrazeKit

#if COCOAPODS
    import TealiumSwift
#else
    import TealiumCore
    import TealiumRemoteCommands
#endif

public class BrazeRemoteCommand: RemoteCommand {

    override public var version: String? {
        return BrazeConstants.version
    }
    let brazeInstance: BrazeCommand
    public var braze: Braze? {
        brazeInstance.braze
    }
    private let location: AnyObject?
    
    public init(brazeInstance: BrazeCommand = BrazeInstance(), type: RemoteCommandType = .webview, brazeLocation: AnyObject? = nil) {
        self.brazeInstance = brazeInstance
        self.location = brazeLocation
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
    
    public func onReady(_ onReady: @escaping (Braze) -> Void) {
        TealiumQueues.backgroundSerialQueue.async {
            self.brazeInstance.onReady(onReady)
        }
    }

    func processRemoteCommand(with payload: [String: Any]) {
        guard let command = payload[BrazeConstants.commandName] as? String else {
                return
        }
        let commands = command.split(separator: BrazeConstants.separator)
        let brazeCommands = commands.map { command in
            return command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        brazeCommands
            .compactMap { BrazeConstants.Commands(rawValue: $0.lowercased()) }
            .forEach { command in
            switch command {
            case .initialize:
                guard let config = createConfig(payload: payload) else { return }
                brazeInstance.initializeBraze(brazeConfig: config)
            case .userIdentifier:
                guard let userIdentifier = payload[BrazeConstants.Keys.userIdentifier] as? String else {
                    return
                }
                self.brazeInstance.changeUser(userIdentifier)
                // TODO: pass auth signature!
            case .userAlias:
                guard let userAlias = payload[BrazeConstants.Keys.userAlias] as? String,
                      let label = payload[BrazeConstants.Keys.aliasLabel] as? String else {
                    return
                }
                brazeInstance.addAlias(userAlias, label: label)
            case .userAttribute:
                brazeInstance.setUserAttributes(payload)
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
                guard let customAttributes = payload[BrazeConstants.Keys.customArrayAttribute] as? [String: [String]] else {
                    return
                }
                customAttributes.forEach { key, value in
                    brazeInstance.setCustomAttributeArrayWithKey(key, array: value)
                }
            case .appendCustomArrayAttribute:
                guard let customAttributes = payload[BrazeConstants.Keys.appendCustomArrayAttribute] as? [String: String] else {
                    return
                }
                customAttributes.forEach { key, value in
                    brazeInstance.addToCustomAttributeArrayWithKey(key, value: value)
                }
            case .removeCustomArrayAttribute:
                guard let customAttributes = payload[BrazeConstants.Keys.removeCustomArrayAttribute] as? [String: String] else {
                    return
                }
                customAttributes.forEach { key, value in
                    brazeInstance.removeFromCustomAttributeArrayWithKey(key, value: value)
                }
            case .emailNotification:
                guard let emailNotification = payload[BrazeConstants.Keys.emailNotification] as? String,
                      let subscriptionType = Braze.User.SubscriptionState.from(emailNotification) else {
                    return
                }
                brazeInstance.setEmailNotificationSubscriptionType(value: subscriptionType)
            case .pushNotification:
                guard let pushNotification = payload[BrazeConstants.Keys.pushNotification] as? String,
                      let subscriptionType = Braze.User.SubscriptionState.from(pushNotification) else {
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
                    let prices = payload[BrazeConstants.Keys.price] as? [Double] else {
                        return
                }
                let products = (productId: productIdentifier, price: prices)

                if let quantity = payload[BrazeConstants.Keys.quantity] as? [Int] {
                    let products = (productId: productIdentifier, price: prices, quantity: quantity)
                    if let properties = payload[BrazeConstants.Keys.purchaseProperties] as? [String: Any] {
                        for (index, element) in products.productId.enumerated() {
                            return brazeInstance.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index], properties: properties)
                        }
                    }
                    for (index, element) in products.productId.enumerated() {
                        brazeInstance.logPurchase(element, currency: currency, price: products.price[index], quantity: products.quantity[index])
                    }
                } else if let properties = payload[BrazeConstants.Keys.purchaseProperties] as? [String: Any] {
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
                brazeInstance.enableSDK(true)
            case .disableSDK:
                brazeInstance.enableSDK(false)
            case .wipeData:
                brazeInstance.wipeData()
            case .flush:
                brazeInstance.flush()
            case .addToSubsriptionGroup:
                guard let groupId = payload[BrazeConstants.Keys.subscriptionGroupId] as? String else { return }
                brazeInstance.addToSubscriptionGroup(groupId)
            case .removeFromSubscriptionGroup:
                guard let groupId = payload[BrazeConstants.Keys.subscriptionGroupId] as? String else { return }
                brazeInstance.removeFromSubscriptionGroup(groupId)
            }
        }
    }
    
    func convertToBool<T>(_ value: T) -> Bool? {
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

    func createConfig(payload: [String: Any]) -> Braze.Configuration? {
        guard let apiKey = payload[BrazeConstants.Keys.apiKey] as? String,
              let endpoint = payload[BrazeConstants.Keys.customEndpoint] as? String else {
            return nil
        }
        var brazeConfig = Braze.Configuration(apiKey: apiKey, endpoint: endpoint)
        
        if let authenticationEnabled = convertToBool(payload[BrazeConstants.Keys.isSdkAuthEnabled]) {
            brazeConfig.api.sdkAuthentication = authenticationEnabled
        }
        if let requestProcessingPolicy = payload[BrazeConstants.Keys.requestProcessingPolicy] as? String,
           let processingPolicy = Braze.Configuration.Api.RequestPolicy.from(requestProcessingPolicy) {
            brazeConfig.api.requestPolicy = processingPolicy
        }
        if let flushInterval = payload[BrazeConstants.Keys.flushInterval] as? Double {
            brazeConfig.api.flushInterval = flushInterval
        }
        if let deviceOptions = payload[BrazeConstants.Keys.deviceOptions] as? [String] {
            brazeConfig.devicePropertyAllowList = Set(deviceOptions.compactMap{Braze.Configuration.DeviceProperty.from($0)})
        }
        if let sessionTimeout = payload[BrazeConstants.Keys.sessionTimeout] as? NSNumber {
            brazeConfig.sessionTimeout = sessionTimeout.doubleValue
        }
        let enableLocation: Bool = !(convertToBool(payload[BrazeConstants.Keys.disableLocation]) ?? false)
        if enableLocation {
            brazeConfig.location.brazeLocation = self.location
            brazeConfig.location.automaticLocationCollection = true
        }
        if let enableGeofences = convertToBool(payload[BrazeConstants.Keys.enableGeofences]) {
            brazeConfig.location.automaticGeofenceRequests = enableGeofences
        }
        if let triggerInterval = payload[BrazeConstants.Keys.triggerIntervalSeconds] as? NSNumber {
            brazeConfig.triggerMinimumTimeInterval = triggerInterval.doubleValue
        }
        if let pushStoryIdentifier = payload[BrazeConstants.Keys.pushStoryIdentifier] as? String {
            brazeConfig.push.appGroup = pushStoryIdentifier
        }
        brazeConfig.api.flavor = .tealium
        return brazeConfig
    }
}

