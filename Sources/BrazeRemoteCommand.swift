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

                guard let productIdentifier = payload[BrazeConstants.Keys.productIdentifier] as? [String],
                    let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                    let prices = payload[BrazeConstants.Keys.price] as? [Double] else {
                        return
                }
                let products = (productId: productIdentifier, price: prices)

                if let quantity = (payload[BrazeConstants.Keys.productQuantity] ?? payload[BrazeConstants.Keys.quantity]) as? [Int] {
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
            case .logProductViewed:
                guard let productId = (payload[BrazeConstants.Keys.productIdentifier] as? [String])?.first,
                      let productName = (payload[BrazeConstants.Keys.productName] as? [String])?.first,
                      let variantId = (payload[BrazeConstants.Keys.variantId] as? [String])?.first,
                      let price = doubleArray(payload[BrazeConstants.Keys.price])?.first,
                      let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String else {
                    print("*** Tealium Remote Command Error - Braze: logProductViewed missing required field(s)")
                    return
                }
                logEcommerceEvent {
                    try Braze.Ecommerce.ProductViewedEvent(
                        productId: productId,
                        productName: productName,
                        variantId: variantId,
                        imageUrl: (payload[BrazeConstants.Keys.imageUrl] as? [String])?.first,
                        productUrl: (payload[BrazeConstants.Keys.productUrl] as? [String])?.first,
                        price: price,
                        currency: currency,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any],
                        typeIdentifiers: payload[BrazeConstants.Keys.typeIdentifiers] as? [String])
                }
            case .logCartUpdatedAdd:
                logCartUpdatedEvent(commandName: "logCartUpdatedAdd", payload: payload) { cartId, currency, source, products in
                    try Braze.Ecommerce.CartUpdated.Add(
                        cartId: cartId,
                        totalValue: doubleValue(payload[BrazeConstants.Keys.totalValue]),
                        currency: currency,
                        subtotalValue: doubleValue(payload[BrazeConstants.Keys.subtotalValue]),
                        tax: doubleValue(payload[BrazeConstants.Keys.tax]),
                        shipping: doubleValue(payload[BrazeConstants.Keys.shipping]),
                        products: products,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any])
                }
            case .logCartUpdatedRemove:
                logCartUpdatedEvent(commandName: "logCartUpdatedRemove", payload: payload) { cartId, currency, source, products in
                    try Braze.Ecommerce.CartUpdated.Remove(
                        cartId: cartId,
                        totalValue: doubleValue(payload[BrazeConstants.Keys.totalValue]),
                        currency: currency,
                        subtotalValue: doubleValue(payload[BrazeConstants.Keys.subtotalValue]),
                        tax: doubleValue(payload[BrazeConstants.Keys.tax]),
                        shipping: doubleValue(payload[BrazeConstants.Keys.shipping]),
                        products: products,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any])
                }
            case .logCartUpdatedReplace:
                // Unlike Add/Remove, the full-snapshot Replace requires a non-optional `total_value`.
                guard let cartId = payload[BrazeConstants.Keys.cartId] as? String,
                      let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String,
                      let totalValue = doubleValue(payload[BrazeConstants.Keys.totalValue]),
                      let products = parseProductLineItems(from: payload) else {
                    print("*** Tealium Remote Command Error - Braze: logCartUpdatedReplace missing required field(s)")
                    return
                }
                logEcommerceEvent {
                    try Braze.Ecommerce.CartUpdated.Replace(
                        cartId: cartId,
                        totalValue: totalValue,
                        currency: currency,
                        subtotalValue: doubleValue(payload[BrazeConstants.Keys.subtotalValue]),
                        tax: doubleValue(payload[BrazeConstants.Keys.tax]),
                        shipping: doubleValue(payload[BrazeConstants.Keys.shipping]),
                        products: products,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any])
                }
            case .logCheckoutStarted:
                guard let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String,
                      let checkoutId = payload[BrazeConstants.Keys.checkoutId] as? String,
                      let totalValue = doubleValue(payload[BrazeConstants.Keys.totalValue]),
                      let products = parseProductLineItems(from: payload) else {
                    print("*** Tealium Remote Command Error - Braze: logCheckoutStarted missing required field(s)")
                    return
                }
                logEcommerceEvent {
                    try Braze.Ecommerce.CheckoutStartedEvent(
                        checkoutId: checkoutId,
                        cartId: payload[BrazeConstants.Keys.cartId] as? String,
                        totalValue: totalValue,
                        currency: currency,
                        subtotalValue: doubleValue(payload[BrazeConstants.Keys.subtotalValue]),
                        tax: doubleValue(payload[BrazeConstants.Keys.tax]),
                        shipping: doubleValue(payload[BrazeConstants.Keys.shipping]),
                        products: products,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any])
                }
            case .logOrderPlaced:
                guard let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String,
                      let orderId = payload[BrazeConstants.Keys.orderId] as? String,
                      let totalValue = doubleValue(payload[BrazeConstants.Keys.totalValue]),
                      let products = parseProductLineItems(from: payload) else {
                    print("*** Tealium Remote Command Error - Braze: logOrderPlaced missing required field(s)")
                    return
                }
                logEcommerceEvent {
                    try Braze.Ecommerce.OrderPlacedEvent(
                        orderId: orderId,
                        cartId: payload[BrazeConstants.Keys.cartId] as? String,
                        totalValue: totalValue,
                        currency: currency,
                        subtotalValue: doubleValue(payload[BrazeConstants.Keys.subtotalValue]),
                        tax: doubleValue(payload[BrazeConstants.Keys.tax]),
                        shipping: doubleValue(payload[BrazeConstants.Keys.shipping]),
                        totalDiscounts: doubleValue(payload[BrazeConstants.Keys.totalDiscounts]),
                        discounts: payload[BrazeConstants.Keys.discounts] as? [Any],
                        products: products,
                        source: source,
                        metadata: payload[BrazeConstants.Keys.eventMetadata] as? [String: Any])
                }
            case .logOrderCancelled:
                guard let orderId = payload[BrazeConstants.Keys.orderId] as? String,
                      let totalValue = doubleValue(payload[BrazeConstants.Keys.totalValue]),
                      let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String,
                      let cancelReason = payload[BrazeConstants.Keys.cancelReason] as? String,
                      let products = buildEcommerceProductDictionaries(from: payload) else {
                    print("*** Tealium Remote Command Error - Braze: logOrderCancelled missing required field(s)")
                    return
                }
                var properties: [String: Any] = [
                    "order_id": orderId,
                    "total_value": totalValue,
                    "currency": currency,
                    "cancel_reason": cancelReason,
                    "products": products,
                    "source": source
                ]
                if let subtotalValue = doubleValue(payload[BrazeConstants.Keys.subtotalValue]) {
                    properties["subtotal_value"] = subtotalValue
                }
                if let tax = doubleValue(payload[BrazeConstants.Keys.tax]) {
                    properties["tax"] = tax
                }
                if let shipping = doubleValue(payload[BrazeConstants.Keys.shipping]) {
                    properties["shipping"] = shipping
                }
                if let totalDiscounts = doubleValue(payload[BrazeConstants.Keys.totalDiscounts]) {
                    properties["total_discounts"] = totalDiscounts
                }
                if let discounts = payload[BrazeConstants.Keys.discounts] as? [Any] {
                    properties["discounts"] = discounts
                }
                if let metadata = payload[BrazeConstants.Keys.eventMetadata] as? [String: Any] {
                    properties["metadata"] = metadata
                }
                brazeInstance.logCustomEvent("ecommerce.order_cancelled", properties: properties)
            case .logOrderRefunded:
                guard let orderId = payload[BrazeConstants.Keys.orderId] as? String,
                      let totalValue = doubleValue(payload[BrazeConstants.Keys.totalValue]),
                      let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
                      let source = payload[BrazeConstants.Keys.productSource] as? String,
                      let products = buildEcommerceProductDictionaries(from: payload) else {
                    print("*** Tealium Remote Command Error - Braze: logOrderRefunded missing required field(s)")
                    return
                }
                var properties: [String: Any] = [
                    "order_id": orderId,
                    "total_value": totalValue,
                    "currency": currency,
                    "products": products,
                    "source": source
                ]
                if let totalDiscounts = doubleValue(payload[BrazeConstants.Keys.totalDiscounts]) {
                    properties["total_discounts"] = totalDiscounts
                }
                if let discounts = payload[BrazeConstants.Keys.discounts] as? [Any] {
                    properties["discounts"] = discounts
                }
                if let metadata = payload[BrazeConstants.Keys.eventMetadata] as? [String: Any] {
                    properties["metadata"] = metadata
                }
                brazeInstance.logCustomEvent("ecommerce.order_refunded", properties: properties)
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

    /// Builds an ecommerce event via the throwing `build` closure and forwards it to Braze.
    /// Braze validates event fields on construction; validation failures are logged and the event is skipped.
    private func logEcommerceEvent<E: Braze.Ecommerce.Event>(_ build: () throws -> E) {
        do {
            let event = try build()
            brazeInstance.logEcommerceEvent(event)
        } catch {
            print("*** Tealium Remote Command Error - Braze: failed to build ecommerce event: \(error)")
        }
    }

    /// Shared dispatch for the three `CartUpdated` variants (Add / Remove / Replace), which have
    /// identical required payloads. Guards the required fields and product list, then delegates
    /// event construction to `build`. `commandName` identifies the caller (Add or Remove) in the
    /// diagnostic printed when required fields are missing.
    private func logCartUpdatedEvent<E: Braze.Ecommerce.Event>(
        commandName: String,
        payload: [String: Any],
        build: (_ cartId: String, _ currency: String, _ source: String, _ products: [Braze.Ecommerce.ProductLineItem]) throws -> E) {
        guard let cartId = payload[BrazeConstants.Keys.cartId] as? String,
              let currency = (payload[BrazeConstants.Keys.productCurrency] ?? payload[BrazeConstants.Keys.currency]) as? String,
              let source = payload[BrazeConstants.Keys.productSource] as? String,
              let products = parseProductLineItems(from: payload) else {
            print("*** Tealium Remote Command Error - Braze: \(commandName) missing required field(s)")
            return
        }
        logEcommerceEvent {
            try build(cartId, currency, source, products)
        }
    }

    /// The parallel product arrays (`product_id`, `product_name`, `variant_id`, `product_qty`,
    /// `product_unit_price`, plus optional `image_url` / `product_url` / `product_metadata`) shared
    /// by both the typed `ProductLineItem` events and the untyped order_cancelled / order_refunded
    /// custom events.
    private struct ProductArrays {
        let productIds: [String]
        let productNames: [String]
        let variantIds: [String]
        let quantities: [Int]
        let prices: [Double]
        let imageUrls: [String]?
        let productUrls: [String]?
        let metadatas: [[String: Any]]?
        let count: Int
    }

    /// Parses and validates the parallel product arrays from the payload. Returns `nil` if any
    /// required array is missing or the array lengths are inconsistent.
    private func parseProductArrays(from payload: [String: Any]) -> ProductArrays? {
        guard let productIds = payload[BrazeConstants.Keys.productIdentifier] as? [String],
              let productNames = payload[BrazeConstants.Keys.productName] as? [String],
              let variantIds = payload[BrazeConstants.Keys.variantId] as? [String],
              let quantities = intArray(payload[BrazeConstants.Keys.productQuantity] ?? payload[BrazeConstants.Keys.quantity]),
              let prices = doubleArray(payload[BrazeConstants.Keys.price]) else {
            return nil
        }
        let count = productIds.count
        guard productNames.count == count,
              variantIds.count == count,
              quantities.count == count,
              prices.count == count else {
            return nil
        }
        return ProductArrays(
            productIds: productIds,
            productNames: productNames,
            variantIds: variantIds,
            quantities: quantities,
            prices: prices,
            imageUrls: payload[BrazeConstants.Keys.imageUrl] as? [String],
            productUrls: payload[BrazeConstants.Keys.productUrl] as? [String],
            metadatas: payload[BrazeConstants.Keys.productMetadata] as? [[String: Any]],
            count: count)
    }

    /// Parses the parallel product arrays into `[ProductLineItem]`, zipping by index. Returns `nil`
    /// if any required array is missing or lengths are inconsistent. Individual `ProductLineItem`
    /// init failures are logged and that product is skipped.
    private func parseProductLineItems(from payload: [String: Any]) -> [Braze.Ecommerce.ProductLineItem]? {
        guard let arrays = parseProductArrays(from: payload) else {
            return nil
        }
        var items = [Braze.Ecommerce.ProductLineItem]()
        for index in 0..<arrays.count {
            do {
                let item = try Braze.Ecommerce.ProductLineItem(
                    productId: arrays.productIds[index],
                    productName: arrays.productNames[index],
                    variantId: arrays.variantIds[index],
                    imageUrl: arrays.imageUrls.flatMap { index < $0.count ? $0[index] : nil },
                    productUrl: arrays.productUrls.flatMap { index < $0.count ? $0[index] : nil },
                    quantity: arrays.quantities[index],
                    price: arrays.prices[index],
                    metadata: arrays.metadatas.flatMap { index < $0.count ? $0[index] : nil })
                items.append(item)
            } catch {
                print("*** Tealium Remote Command Error - Braze: failed to build product line item at index \(index): \(error)")
            }
        }
        return items
    }

    /// Builds raw `[String: Any]` product dictionaries (matching Braze's `ecommerce.order_cancelled` /
    /// `ecommerce.order_refunded` custom event schema) from the same parallel product arrays used by
    /// `parseProductLineItems`. Braze has no typed SDK class for these events, so no SDK-side
    /// field validation is performed here.
    private func buildEcommerceProductDictionaries(from payload: [String: Any]) -> [[String: Any]]? {
        guard let arrays = parseProductArrays(from: payload) else {
            return nil
        }
        var products = [[String: Any]]()
        for index in 0..<arrays.count {
            var product: [String: Any] = [
                "product_id": arrays.productIds[index],
                "product_name": arrays.productNames[index],
                "variant_id": arrays.variantIds[index],
                "quantity": arrays.quantities[index],
                "price": arrays.prices[index]
            ]
            if let imageUrl = arrays.imageUrls.flatMap({ index < $0.count ? $0[index] : nil }) {
                product["image_url"] = imageUrl
            }
            if let productUrl = arrays.productUrls.flatMap({ index < $0.count ? $0[index] : nil }) {
                product["product_url"] = productUrl
            }
            if let metadata = arrays.metadatas.flatMap({ index < $0.count ? $0[index] : nil }) {
                product["metadata"] = metadata
            }
            products.append(product)
        }
        return products
    }

    /// Casts a payload value to `[Int]`, first attempting `[NSNumber]`. Numeric arrays in the payload
    /// often arrive as `[NSNumber]` (from the webview/JSON bridge) rather than native `[Int]`; the
    /// `NSNumber` path also recovers native `[Double]` values that hold whole numbers.
    private func intArray(_ value: Any?) -> [Int]? {
        if let array = value as? [NSNumber] {
            return array.map { $0.intValue }
        }
        return value as? [Int]
    }

    /// Casts a payload value to `[Double]`, first attempting `[NSNumber]`. This is required because a
    /// native Swift `[Int]` (e.g. `product_unit_price: [60, 20]` with no decimals) fails a direct
    /// `as? [Double]` cast; routing through `NSNumber` recovers it, since Swift `Int` bridges to `NSNumber`.
    private func doubleArray(_ value: Any?) -> [Double]? {
        if let array = value as? [NSNumber] {
            return array.map { $0.doubleValue }
        }
        return value as? [Double]
    }

    /// Casts a payload value to `Double`, first attempting `NSNumber`. This is required because a
    /// native Swift `Int` (e.g. `total_value: 200` with no decimals) fails a direct `as? Double`
    /// cast; routing through `NSNumber` recovers it, since Swift `Int` bridges to `NSNumber`.
    private func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double
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
        if let flushInterval = payload[BrazeConstants.Keys.flushInterval] as? Double {
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
        if let useUUIDAsDeviceId = payload[BrazeConstants.Keys.useUUIDAsDeviceId] as? NSNumber {
            brazeConfig.useUUIDAsDeviceId = useUUIDAsDeviceId.boolValue
        }
        if let deviceOptions = payload[BrazeConstants.Keys.deviceOptions] as? [String] {
            brazeConfig.devicePropertyAllowList = Set(deviceOptions.compactMap{Braze.Configuration.DeviceProperty.from($0)})
        }
        if let sessionTimeout = payload[BrazeConstants.Keys.sessionTimeout] as? NSNumber {
            brazeConfig.sessionTimeout = sessionTimeout.doubleValue
        }
        if let triggerInterval = payload[BrazeConstants.Keys.triggerIntervalSeconds] as? NSNumber {
            brazeConfig.triggerMinimumTimeInterval = triggerInterval.doubleValue
        }
        if let forwardUniversalLinks = payload[BrazeConstants.Keys.forwardUniversalLinks] as? NSNumber {
            brazeConfig.forwardUniversalLinks = forwardUniversalLinks.boolValue
        }
        if let optInWhenPushAuthorized = payload[BrazeConstants.Keys.optInWhenPushAuthorized] as? Bool {
            brazeConfig.optInWhenPushAuthorized = optInWhenPushAuthorized
        }

        return brazeConfig
    }
}
