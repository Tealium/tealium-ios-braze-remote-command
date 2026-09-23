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
                self.brazeInstance.changeUser(userIdentifier, sdkAuthSignature: payload[BrazeConstants.Keys.sdkAuthSignature] as? String)
            case .setSdkAuthSignature:
                guard let signature = payload[BrazeConstants.Keys.sdkAuthSignature] as? String else {
                    return
                }
                self.brazeInstance.setSdkAuthenticationSignature(signature)
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

                // Accepts both the logpurchase and the ecommerce spellings; see BrazeConstants.keyAliases.
                // Braze logs one product per call, so the parallel payload arrays are fanned out by
                // index -- hence the plural names. Prices go through `optionalValue` so numeric
                // strings coerce the same way they do for the ecommerce commands.
                guard let productIds = payload[BrazeConstants.Keys.productId] as? [String],
                    let currency = payload.canonicalValue(BrazeConstants.Keys.currency) as? String,
                    let prices: [Double] = payload.optionalValue(BrazeConstants.Keys.price) else {
                        return
                }

                // productIds and prices are parallel arrays; a length mismatch would
                // trap on out-of-bounds access in the loop below, so reject it up front.
                guard prices.count == productIds.count else {
                    print("*** Tealium Remote Command Error - Braze: logPurchase productId and price arrays must be the same length")
                    return
                }

                // Quantity is optional per product: missing, wrong-length or non-Int entries become
                // nil and the Braze SDK applies its own default, rather than dropping the purchase.
                let quantities: [Int?] = payload.optionalArray(BrazeConstants.Keys.quantity, count: productIds.count)
                    ?? Array(repeating: nil, count: productIds.count)
                let properties = payload[BrazeConstants.Keys.purchaseProperties] as? [String: Any]
                for (index, productId) in productIds.enumerated() {
                    brazeInstance.logPurchase(
                        productId,
                        currency: currency,
                        price: prices[index],
                        quantity: quantities[index],
                        properties: properties
                    )
                }
            case .logProductViewed:
                logEcommerceEvent(commandName: "logProductViewed") {
                    try EcommerceEventParser.parseProductViewedEvent(payload: payload)
                }
            case .logCartUpdated:
                guard let action = BrazeConstants.Ecommerce.Action.from(payload[BrazeConstants.Keys.action]) else {
                    let rawAction = payload[BrazeConstants.Keys.action] ?? ""
                    print("*** Tealium Remote Command Error - Braze: logCartUpdated unrecognized action '\(rawAction)' -- expected add, remove or replace, or omit the key for a full-cart snapshot")
                    return
                }
                switch action {
                case .add:
                    logEcommerceEvent(commandName: "logCartUpdated") {
                        try EcommerceEventParser.parseCartUpdatedAddEvent(payload: payload)
                    }
                case .remove:
                    logEcommerceEvent(commandName: "logCartUpdated") {
                        try EcommerceEventParser.parseCartUpdatedRemoveEvent(payload: payload)
                    }
                case .replace:
                    logEcommerceEvent(commandName: "logCartUpdated") {
                        try EcommerceEventParser.parseCartUpdatedReplaceEvent(payload: payload)
                    }
                }
            case .logCheckoutStarted:
                logEcommerceEvent(commandName: "logCheckoutStarted") {
                    try EcommerceEventParser.parseCheckoutStartedEvent(payload: payload)
                }
            case .logOrderPlaced:
                logEcommerceEvent(commandName: "logOrderPlaced") {
                    try EcommerceEventParser.parseOrderPlacedEvent(payload: payload)
                }
            case .logOrderCancelled:
                logCustomEcommerceEvent(commandName: "logOrderCancelled") {
                    try EcommerceEventParser.parseOrderCancelledEvent(payload: payload)
                }
            case .logOrderRefunded:
                logCustomEcommerceEvent(commandName: "logOrderRefunded") {
                    try EcommerceEventParser.parseOrderRefundedEvent(payload: payload)
                }
            case .setAdTrackingEnabled:
                guard let enabled = convertToBool(payload[BrazeConstants.Keys.adTrackingEnabled]) else {
                    return
                }
                self.brazeInstance.setAdTrackingEnabled(enabled)
            case .setIdentifierForAdvertiser:
                guard let identifier = payload[BrazeConstants.Keys.advertiserIdentifier] as? String else {
                    return
                }
                self.brazeInstance.setIdentifierForAdvertiser(identifier)
            case .setIdentifierForVendor:
                guard let identifier = payload[BrazeConstants.Keys.vendorIdentifier] as? String else {
                    return
                }
                self.brazeInstance.setIdentifierForVendor(identifier)
            case .setLastKnownLocation:
                // optionalValue, not `as? Double`: AnyDecodable decodes a JSON `10` as Int, which a direct Double cast silently drops.
                guard let latitude: Double = payload.optionalValue(BrazeConstants.Keys.latitude),
                    let longitude: Double = payload.optionalValue(BrazeConstants.Keys.longitude),
                    let horizontalAccuracy: Double = payload.optionalValue(BrazeConstants.Keys.horizontalAccuracy) else {
                        print("""
                                *** Tealium Remote Command Error - Braze: In order to set the user's last known location,
                                you must provide latitude, longitude, and horizontal accuracy.
                              """)
                        return
                }
                guard let altitude: Double = payload.optionalValue(BrazeConstants.Keys.altitude),
                    let verticalAccuracy: Double = payload.optionalValue(BrazeConstants.Keys.verticalAccuracy) else {
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
            case .logout:
                brazeInstance.logout()
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

    /// Builds an ecommerce event via the throwing `build` closure and forwards it to Braze.
    /// Parsing failures (`ParsingError`) and SDK validation failures on construction are both
    /// logged (tagged with `commandName`) and the event is skipped.
    private func logEcommerceEvent<E: Braze.Ecommerce.Event>(commandName: String, _ build: () throws -> E) {
        do {
            let event = try build()
            brazeInstance.logEcommerceEvent(event)
        } catch {
            print("*** Tealium Remote Command Error - Braze: \(commandName) failed to build ecommerce event: \(error)")
        }
    }

    /// Builds an order_cancelled / order_refunded custom event (no typed Braze SDK class exists)
    /// via the throwing `build` closure and forwards it through `logCustomEvent`.
    private func logCustomEcommerceEvent(commandName: String, _ build: () throws -> CustomEvent) {
        do {
            let event = try build()
            brazeInstance.logCustomEvent(event.eventName, properties: event.properties)
        } catch {
            print("*** Tealium Remote Command Error - Braze: \(commandName) failed to build ecommerce event: \(error)")
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
        let brazeConfig = Braze.Configuration(apiKey: apiKey, endpoint: endpoint)

        // API Config
        if let authenticationEnabled = convertToBool(payload[BrazeConstants.Keys.isSdkAuthEnabled]) {
            brazeConfig.api.sdkAuthentication = authenticationEnabled
        }
        if let requestProcessingPolicy = payload[BrazeConstants.Keys.requestProcessingPolicy] as? String,
           let processingPolicy = Braze.Configuration.Api.RequestPolicy.from(requestProcessingPolicy) {
            brazeConfig.api.requestPolicy = processingPolicy
        }
        // optionalValue, not `as? Double`: AnyDecodable decodes a JSON `10` as Int, which a direct Double cast silently drops.
        if let flushInterval: Double = payload.optionalValue(BrazeConstants.Keys.flushInterval) {
            brazeConfig.api.flushInterval = flushInterval
        }

        brazeConfig.api.sdkFlavor = .tealium

        // Location Config
        brazeConfig.location.brazeLocationProvider = self.location
        if let enableAutomaticLocation = convertToBool(payload[BrazeConstants.Keys.enableAutomaticLocation]) {
            brazeConfig.location.automaticLocationCollection = enableAutomaticLocation
        }
        if let enableGeofences = convertToBool(payload[BrazeConstants.Keys.enableGeofences]) {
            brazeConfig.location.geofencesEnabled = enableGeofences
        }
        if let enableAutomaticGeofences = convertToBool(payload[BrazeConstants.Keys.enableAutomaticGeofences]) {
            brazeConfig.location.automaticGeofenceRequests = enableAutomaticGeofences
        }

        // Push Config
        if let pushStoryIdentifier = payload[BrazeConstants.Keys.pushStoryIdentifier] as? String {
            brazeConfig.push.appGroup = pushStoryIdentifier
        }

        // BrazeConfig properties
        if let useUUIDAsDeviceId = convertToBool(payload[BrazeConstants.Keys.useUUIDAsDeviceId]) {
            brazeConfig.useUUIDAsDeviceId = useUUIDAsDeviceId
        }
        if let deviceOptions = payload[BrazeConstants.Keys.deviceOptions] as? [String] {
            brazeConfig.devicePropertyAllowList = Set(deviceOptions.compactMap{Braze.Configuration.DeviceProperty.from($0)})
        }
        if let sessionTimeout: Double = payload.optionalValue(BrazeConstants.Keys.sessionTimeout) {
            brazeConfig.sessionTimeout = sessionTimeout
        }
        if let triggerInterval: Double = payload.optionalValue(BrazeConstants.Keys.triggerIntervalSeconds) {
            brazeConfig.triggerMinimumTimeInterval = triggerInterval
        }
        if let forwardUniversalLinks = convertToBool(payload[BrazeConstants.Keys.forwardUniversalLinks]) {
            brazeConfig.forwardUniversalLinks = forwardUniversalLinks
        }
        if let optInWhenPushAuthorized = convertToBool(payload[BrazeConstants.Keys.optInWhenPushAuthorized]) {
            brazeConfig.optInWhenPushAuthorized = optInWhenPushAuthorized
        }

        return brazeConfig
    }
}
