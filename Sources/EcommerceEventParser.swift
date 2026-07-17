//
//  EcommerceEventParser.swift
//  TealiumBraze
//

import Foundation
import BrazeKit

// MARK: - Errors & supporting types

enum ParsingError: Error, CustomStringConvertible {
    case missingField(String)
    case typeMismatch(field: String, expected: String, actual: String)
    case mismatchedArrayLengths(fields: [String])

    var description: String {
        switch self {
        case .missingField(let field):
            return "missing required field '\(field)'"
        case .typeMismatch(let field, let expected, let actual):
            return "field '\(field)' expected \(expected) but found \(actual)"
        case .mismatchedArrayLengths(let fields):
            return "mismatched array lengths across fields: \(fields.joined(separator: ", "))"
        }
    }
}

/// Represents `ecommerce.order_cancelled` / `ecommerce.order_refunded`, for which Braze has no
/// typed SDK event class. Deliberately does NOT conform to `Braze.Ecommerce.Event` — these are
/// dispatched via `logCustomEvent(_:properties:)`, a distinct SDK path from `logEcommerceEvent(_:)`.
struct CustomEvent {
    let eventName: String
    let properties: [String: Any]
}

extension [String: Any] {
    func get(key: String, fallbackKey: String? = nil) -> Any? {
        if let value = self[key] { return value }
        if let fallbackKey = fallbackKey { return self[fallbackKey] }
        return nil
    }

    /// Reads a required field as `T`, falling back to NSNumber-bridging for `Double`/`Int`/
    /// `[Double]`/`[Int]` when a direct cast fails (native `Int` payloads from the JS bridge
    /// fail a direct `as? Double` cast; routing through `NSNumber` recovers them).
    func require<T>(_ key: String, fallbackKey: String? = nil) throws -> T {
        guard let raw = get(key: key, fallbackKey: fallbackKey) else {
            throw ParsingError.missingField(fallbackKey.map { "\(key) or \($0)" } ?? key)
        }
        if let value = raw as? T {
            return value
        }
        if T.self == Double.self, let number = raw as? NSNumber {
            return number.doubleValue as! T
        }
        if T.self == Int.self, let number = raw as? NSNumber {
            return number.intValue as! T
        }
        if T.self == [Double].self, let array = raw as? [NSNumber] {
            return array.map { $0.doubleValue } as! T
        }
        if T.self == [Int].self, let array = raw as? [NSNumber] {
            return array.map { $0.intValue } as! T
        }
        throw ParsingError.typeMismatch(
            field: key, expected: String(describing: T.self), actual: String(describing: Swift.type(of: raw)))
    }

    /// Same NSNumber-bridging as `require<T>`, but returns `nil` instead of throwing when the key
    /// is absent or the value can't be coerced to `T`. Use for genuinely optional numeric fields
    /// (`total_value` on Add/Remove, `tax`, `shipping`, etc.).
    func optionalValue<T>(_ key: String) -> T? {
        guard let raw = self[key] else { return nil }
        if let value = raw as? T { return value }
        if T.self == Double.self, let number = raw as? NSNumber {
            return number.doubleValue as? T
        }
        if T.self == Int.self, let number = raw as? NSNumber {
            return number.intValue as? T
        }
        if T.self == [Double].self, let array = raw as? [NSNumber] {
            return array.map { $0.doubleValue } as? T
        }
        if T.self == [Int].self, let array = raw as? [NSNumber] {
            return array.map { $0.intValue } as? T
        }
        return nil
    }

    /// Reads an optional per-product array field (e.g. `image_url`), tolerating individual `nil`/
    /// mismatched-type elements as `nil` rather than discarding every element in the array. Casting
    /// the whole array to `[String]` would turn one product's missing `image_url` into ALL products
    /// losing their `image_url`, since `NSNull`/non-`String` elements make the whole-array cast fail.
    /// Also drops the field entirely if its length doesn't match the other parallel arrays, since a
    /// misaligned array can't be safely indexed by product.
    func optionalArray<T>(_ key: String, count: Int) -> [T?]? {
        guard let raw = self[key] as? [Any], raw.count == count else { return nil }
        return raw.map { $0 as? T }
    }

    /// Event-level custom metadata, read from `Keys.eventMetadata`. Every ecommerce event carries
    /// this optional field under the same key.
    var ecommerceEventMetadata: [String: Any]? {
        self[BrazeConstants.Keys.eventMetadata] as? [String: Any]
    }

    /// Merges `required` with whichever `optional` entries are non-`nil`, omitting the rest.
    /// Avoids the `var dict = [...]; if let x { dict[k] = x }` repetition seen for every optional
    /// field on `order_cancelled`/`order_refunded`'s wire properties, and -- unlike unwrapping each
    /// optional with `as Any` inline -- never leaves a JSON `null` in the result for an absent field.
    static func merging(_ required: [String: Any], ifPresent optional: [String: Any?]) -> [String: Any] {
        var result = required
        for (key, value) in optional {
            if let value {
                result[key] = value
            }
        }
        return result
    }
}

// MARK: - EcommerceEventParser

final class EcommerceEventParser {
    typealias Keys = BrazeConstants.Keys

    // MARK: Product Viewed (fires one event per parallel-array index)

    /// Validates the shared product-viewed fields once, then returns one throwing builder
    /// closure per product. Each closure independently constructs a `ProductViewedEvent`; the
    /// caller fires each with its own `logEcommerceEvent`, so one product's SDK-validation
    /// failure does not affect its siblings.
    static func parseProductViewedEventBuilders(
        payload: [String: Any]
    ) throws -> [() throws -> Braze.Ecommerce.ProductViewedEvent] {
        let productIds = try requireLenientStringArray(payload: payload, key: Keys.productIdentifier)
        let productNames = try requireLenientStringArray(payload: payload, key: Keys.productName)
        let variantIds = try requireLenientStringArray(payload: payload, key: Keys.variantId)
        let prices = try requireLenientDoubleArray(payload: payload, key: Keys.price)
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)

        guard productIds.count == productNames.count,
              productNames.count == variantIds.count,
              variantIds.count == prices.count else {
            throw ParsingError.mismatchedArrayLengths(
                fields: [Keys.productIdentifier, Keys.productName, Keys.variantId, Keys.price])
        }

        let count = productIds.count
        let imageUrls = lenientOptionalStringArray(payload[Keys.imageUrl], count: count)
        let productUrls = lenientOptionalStringArray(payload[Keys.productUrl], count: count)
        let metadata = payload.ecommerceEventMetadata
        let typeIdentifiers = payload[Keys.typeIdentifiers] as? [String]

        return productIds.indices.map { index in
            {
                try Braze.Ecommerce.ProductViewedEvent(
                    productId: productIds[index],
                    productName: productNames[index],
                    variantId: variantIds[index],
                    imageUrl: imageUrls?[index],
                    productUrl: productUrls?[index],
                    price: prices[index],
                    currency: currency,
                    source: source,
                    metadata: metadata,
                    typeIdentifiers: typeIdentifiers)
            }
        }
    }

    // MARK: Cart Updated (Add / Remove / Replace)

    static func parseCartUpdatedAddEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CartUpdated.Add {
        try parseCartUpdatedEvent(payload: payload) { cartId, currency, source, products in
            try Braze.Ecommerce.CartUpdated.Add(
                cartId: cartId,
                totalValue: payload.optionalValue(Keys.totalValue),
                currency: currency,
                subtotalValue: payload.optionalValue(Keys.subtotalValue),
                tax: payload.optionalValue(Keys.tax),
                shipping: payload.optionalValue(Keys.shipping),
                products: products,
                source: source,
                metadata: payload.ecommerceEventMetadata)
        }
    }

    static func parseCartUpdatedRemoveEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CartUpdated.Remove {
        try parseCartUpdatedEvent(payload: payload) { cartId, currency, source, products in
            try Braze.Ecommerce.CartUpdated.Remove(
                cartId: cartId,
                totalValue: payload.optionalValue(Keys.totalValue),
                currency: currency,
                subtotalValue: payload.optionalValue(Keys.subtotalValue),
                tax: payload.optionalValue(Keys.tax),
                shipping: payload.optionalValue(Keys.shipping),
                products: products,
                source: source,
                metadata: payload.ecommerceEventMetadata)
        }
    }

    static func parseCartUpdatedReplaceEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CartUpdated.Replace {
        // Unlike Add/Remove, the full-snapshot Replace requires a non-optional `total_value`.
        let totalValue: Double = try payload.require(Keys.totalValue)
        return try parseCartUpdatedEvent(payload: payload) { cartId, currency, source, products in
            try Braze.Ecommerce.CartUpdated.Replace(
                cartId: cartId,
                totalValue: totalValue,
                currency: currency,
                subtotalValue: payload.optionalValue(Keys.subtotalValue),
                tax: payload.optionalValue(Keys.tax),
                shipping: payload.optionalValue(Keys.shipping),
                products: products,
                source: source,
                metadata: payload.ecommerceEventMetadata)
        }
    }

    /// Shared guard for the three `CartUpdated` variants: cartId, currency, source, and a valid
    /// product list. Delegates SDK construction to `build`.
    private static func parseCartUpdatedEvent<E: Braze.Ecommerce.Event>(
        payload: [String: Any],
        build: (_ cartId: String, _ currency: String, _ source: String, _ products: [Braze.Ecommerce.ProductLineItem]) throws -> E
    ) throws -> E {
        let cartId: String = try payload.require(Keys.cartId)
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)
        let products = try parseProductLineItems(from: payload)
        return try build(cartId, currency, source, products)
    }

    // MARK: Checkout Started / Order Placed

    static func parseCheckoutStartedEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CheckoutStartedEvent {
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)
        let checkoutId: String = try payload.require(Keys.checkoutId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let products = try parseProductLineItems(from: payload)
        return try Braze.Ecommerce.CheckoutStartedEvent(
            checkoutId: checkoutId,
            cartId: payload[Keys.cartId] as? String,
            totalValue: totalValue,
            currency: currency,
            subtotalValue: payload.optionalValue(Keys.subtotalValue),
            tax: payload.optionalValue(Keys.tax),
            shipping: payload.optionalValue(Keys.shipping),
            products: products,
            source: source,
            metadata: payload.ecommerceEventMetadata)
    }

    static func parseOrderPlacedEvent(payload: [String: Any]) throws -> Braze.Ecommerce.OrderPlacedEvent {
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let products = try parseProductLineItems(from: payload)
        return try Braze.Ecommerce.OrderPlacedEvent(
            orderId: orderId,
            cartId: payload[Keys.cartId] as? String,
            totalValue: totalValue,
            currency: currency,
            subtotalValue: payload.optionalValue(Keys.subtotalValue),
            tax: payload.optionalValue(Keys.tax),
            shipping: payload.optionalValue(Keys.shipping),
            totalDiscounts: payload.optionalValue(Keys.totalDiscounts),
            discounts: payload[Keys.discounts] as? [Any],
            products: products,
            source: source,
            metadata: payload.ecommerceEventMetadata)
    }

    // MARK: Order Cancelled / Refunded (custom events, no typed SDK class)

    static func parseOrderCancelledEvent(payload: [String: Any]) throws -> CustomEvent {
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)
        let cancelReason: String = try payload.require(Keys.cancelReason)
        let products = try buildEcommerceProductDictionaries(from: payload)

        let properties = [String: Any].merging(
            [
                Keys.orderId: orderId,
                Keys.totalValue: totalValue,
                Keys.wireOutputCurrency: currency,
                Keys.cancelReason: cancelReason,
                Keys.wireOutputProducts: products,
                Keys.wireOutputSource: source
            ],
            ifPresent: [
                Keys.subtotalValue: payload.optionalValue(Keys.subtotalValue) as Double?,
                Keys.tax: payload.optionalValue(Keys.tax) as Double?,
                Keys.shipping: payload.optionalValue(Keys.shipping) as Double?,
                Keys.totalDiscounts: payload.optionalValue(Keys.totalDiscounts) as Double?,
                Keys.discounts: payload[Keys.discounts] as? [Any],
                Keys.wireOutputMetadata: payload.ecommerceEventMetadata
            ])
        return CustomEvent(eventName: "ecommerce.order_cancelled", properties: properties)
    }

    static func parseOrderRefundedEvent(payload: [String: Any]) throws -> CustomEvent {
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let currency: String = try payload.require(Keys.productCurrency)
        let source: String = try payload.require(Keys.productSource)
        let products = try buildEcommerceProductDictionaries(from: payload)

        let properties = [String: Any].merging(
            [
                Keys.orderId: orderId,
                Keys.totalValue: totalValue,
                Keys.wireOutputCurrency: currency,
                Keys.wireOutputProducts: products,
                Keys.wireOutputSource: source
            ],
            ifPresent: [
                Keys.totalDiscounts: payload.optionalValue(Keys.totalDiscounts) as Double?,
                Keys.discounts: payload[Keys.discounts] as? [Any],
                Keys.wireOutputMetadata: payload.ecommerceEventMetadata
            ])
        return CustomEvent(eventName: "ecommerce.order_refunded", properties: properties)
    }

    // MARK: Shared product-array parsing (used by both typed line items and raw dictionaries)

    private struct ProductArrays {
        let productIds: [String]
        let productNames: [String]
        let variantIds: [String]
        let quantities: [Int]
        let prices: [Double]
        let imageUrls: [String?]?
        let productUrls: [String?]?
        let metadatas: [[String: Any]?]?
        let count: Int
    }

    private static func parseProductArrays(from payload: [String: Any]) throws -> ProductArrays {
        let productIds: [String] = try payload.require(Keys.productIdentifier)
        let productNames: [String] = try payload.require(Keys.productName)
        let variantIds: [String] = try payload.require(Keys.variantId)
        let quantities: [Int] = try payload.require(Keys.productQuantity, fallbackKey: Keys.quantity)
        let prices: [Double] = try payload.require(Keys.price)

        let count = productIds.count
        guard productNames.count == count,
              variantIds.count == count,
              quantities.count == count,
              prices.count == count else {
            throw ParsingError.mismatchedArrayLengths(
                fields: [Keys.productIdentifier, Keys.productName, Keys.variantId, Keys.productQuantity, Keys.price])
        }
        return ProductArrays(
            productIds: productIds,
            productNames: productNames,
            variantIds: variantIds,
            quantities: quantities,
            prices: prices,
            imageUrls: payload.optionalArray(Keys.imageUrl, count: count),
            productUrls: payload.optionalArray(Keys.productUrl, count: count),
            metadatas: payload.optionalArray(Keys.productMetadata, count: count),
            count: count)
    }

    /// Individual `ProductLineItem` construction failures are logged and that product is
    /// skipped -- a recoverable, per-item condition (not a whole-parse failure), so it is
    /// caught locally rather than propagated as a `ParsingError`.
    private static func parseProductLineItems(from payload: [String: Any]) throws -> [Braze.Ecommerce.ProductLineItem] {
        let arrays = try parseProductArrays(from: payload)
        var items = [Braze.Ecommerce.ProductLineItem]()
        for index in 0..<arrays.count {
            do {
                let item = try Braze.Ecommerce.ProductLineItem(
                    productId: arrays.productIds[index],
                    productName: arrays.productNames[index],
                    variantId: arrays.variantIds[index],
                    imageUrl: arrays.imageUrls?[index],
                    productUrl: arrays.productUrls?[index],
                    quantity: arrays.quantities[index],
                    price: arrays.prices[index],
                    metadata: arrays.metadatas?[index])
                items.append(item)
            } catch {
                print("*** Tealium Remote Command Error - Braze: failed to build product line item at index \(index): \(error)")
            }
        }
        return items
    }

    private static func buildEcommerceProductDictionaries(from payload: [String: Any]) throws -> [[String: Any]] {
        let arrays = try parseProductArrays(from: payload)
        var products = [[String: Any]]()
        for index in 0..<arrays.count {
            var product: [String: Any] = [
                Keys.productIdentifier: arrays.productIds[index],
                Keys.productName: arrays.productNames[index],
                Keys.variantId: arrays.variantIds[index],
                Keys.wireOutputQuantity: arrays.quantities[index],
                Keys.wireOutputPrice: arrays.prices[index]
            ]
            if let imageUrl = arrays.imageUrls?[index] {
                product[Keys.imageUrl] = imageUrl
            }
            if let productUrl = arrays.productUrls?[index] {
                product[Keys.productUrl] = productUrl
            }
            if let metadata = arrays.metadatas?[index] {
                product[Keys.wireOutputMetadata] = metadata
            }
            products.append(product)
        }
        return products
    }

    // MARK: Scalar-or-array leniency for logProductViewed only

    private static func requireLenientStringArray(payload: [String: Any], key: String) throws -> [String] {
        guard let raw = payload[key] else {
            throw ParsingError.missingField(key)
        }
        if let array = raw as? [String] { return array }
        if let scalar = raw as? String { return [scalar] }
        throw ParsingError.typeMismatch(
            field: key, expected: "String or [String]", actual: String(describing: Swift.type(of: raw)))
    }

    private static func requireLenientDoubleArray(payload: [String: Any], key: String) throws -> [Double] {
        guard let raw = payload[key] else {
            throw ParsingError.missingField(key)
        }
        if let array: [Double] = payload.optionalValue(key) { return array }
        if let scalar: Double = payload.optionalValue(key) { return [scalar] }
        throw ParsingError.typeMismatch(
            field: key, expected: "Double or [Double]", actual: String(describing: Swift.type(of: raw)))
    }

    /// Same whole-array-cast pitfall as `[String: Any].optionalArray` (see its doc comment), plus
    /// tolerance for a single scalar value in place of a one-element array.
    private static func lenientOptionalStringArray(_ value: Any?, count: Int) -> [String?]? {
        if let scalar = value as? String { return count == 1 ? [scalar] : nil }
        guard let array = value as? [Any], array.count == count else { return nil }
        return array.map { $0 as? String }
    }
}
