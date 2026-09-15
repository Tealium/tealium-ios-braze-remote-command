//
//  EcommerceEventParser.swift
//  TealiumBraze
//

import Foundation
import BrazeKit

// MARK: - Errors & supporting types

enum ParsingError: Error, CustomStringConvertible {
    case missingField(String)
    case emptyField(String)
    case invalidAmount(field: String)
    case typeMismatch(field: String, expected: String, actual: String)
    case mismatchedArrayLengths(fields: [String])
    case emptyProducts

    var description: String {
        switch self {
        case .missingField(let field):
            return "missing required field '\(field)'"
        case .emptyField(let field):
            return "required field '\(field)' is empty"
        case .invalidAmount(let field):
            return "field '\(field)' must be a finite amount of 0 or more"
        case .typeMismatch(let field, let expected, let actual):
            return "field '\(field)' expected \(expected) but found \(actual)"
        case .mismatchedArrayLengths(let fields):
            return "mismatched array lengths across fields: \(fields.joined(separator: ", "))"
        case .emptyProducts:
            return "no valid products -- Braze requires a non-empty products array"
        }
    }
}

/// Represents order_cancelled/order_refunded — Braze has no typed SDK class for these, so they're
/// dispatched via `logCustomEvent`, not `logEcommerceEvent`.
struct CustomEvent {
    let eventName: String
    let properties: [String: Any]
}

extension [String: Any] {
    /// Casts `raw` to `T`. Falls back to NSNumber-bridging (JS bridge sends native `Int` where a
    /// `Double` is expected) and String→number parsing (data layers often send numbers as strings,
    /// e.g. `price:"19.99"`), per-element for array types. Returns `nil` if no path applies.
    private func lenientCast<T>(_ raw: Any, as type: T.Type) -> T? {
        if let value = raw as? T { return value }
        // Bool bridges to NSNumber; reject explicitly so `price: true` isn't coerced to 1.0/0.0.
        if raw is Bool { return nil }
        if T.self == Double.self {
            if let number = raw as? NSNumber, number.doubleValue.isFinite { return number.doubleValue as? T }
            if let string = raw as? String, let value = Double(string), value.isFinite { return value as? T }
        }
        if T.self == Int.self {
            // Int(exactly:) rejects fractional (1.5) and out-of-range (1e100) values instead of
            // truncating or trapping, unlike NSNumber.intValue.
            if let number = raw as? NSNumber, let value = Int(exactly: number.doubleValue) {
                return value as? T
            }
            if let string = raw as? String, let value = Int(string) { return value as? T }
        }
        if T.self == [Double].self {
            // Per-element coercion so a mixed array like [59.99, "19.99"] recovers instead of
            // failing a whole-array cast. Any unparseable element rejects the whole array.
            if let array = raw as? [Any] {
                var doubles = [Double]()
                for element in array {
                    if element is Bool {
                        return nil
                    } else if let number = element as? NSNumber, number.doubleValue.isFinite {
                        doubles.append(number.doubleValue)
                    } else if let string = element as? String, let value = Double(string), value.isFinite {
                        doubles.append(value)
                    } else {
                        return nil
                    }
                }
                return doubles as? T
            }
        }
        if T.self == [Int].self {
            // Same per-element coercion as [Double] above.
            if let array = raw as? [Any] {
                var ints = [Int]()
                for element in array {
                    if element is Bool {
                        return nil
                    } else if let number = element as? NSNumber {
                        guard let value = Int(exactly: number.doubleValue) else { return nil }
                        ints.append(value)
                    } else if let string = element as? String, let value = Int(string) {
                        ints.append(value)
                    } else {
                        return nil
                    }
                }
                return ints as? T
            }
        }
        return nil
    }

    /// Required field as `T`. Throws `missingField` when absent, `typeMismatch` when not coercible.
    fileprivate func require<T>(_ key: String) throws -> T {
        guard let raw = canonicalValue(key) else {
            throw ParsingError.missingField(key)
        }
        guard let value: T = lenientCast(raw, as: T.self) else {
            throw ParsingError.typeMismatch(
                field: key, expected: String(describing: T.self), actual: String(describing: Swift.type(of: raw)))
        }
        return value
    }

    /// Required non-blank String. Needed for order_cancelled/order_refunded (orderId, source,
    /// cancelReason, currency) since those have no typed SDK class and Braze doesn't validate a
    /// manually logged custom event -- a blank value would otherwise fail invisibly after ingestion.
    fileprivate func requireNonEmpty(_ key: String) throws -> String {
        let value: String = try require(key)
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParsingError.emptyField(key)
        }
        return value
    }

    /// Required non-negative finite amount. Same rationale as `requireNonEmpty` -- unvalidated
    /// custom-event path (order_cancelled/order_refunded totalValue).
    fileprivate func requireAmount(_ key: String) throws -> Double {
        let value: Double = try require(key)
        guard value.isFinite, value >= 0 else {
            throw ParsingError.invalidAmount(field: key)
        }
        return value
    }

    /// Like `require`, but returns `nil` instead of throwing -- for optional numeric fields
    /// (`tax`, `shipping`, `total_value` on add/remove, etc.).
    fileprivate func optionalValue<T>(_ key: String) -> T? {
        guard let raw = canonicalValue(key) else { return nil }
        return lenientCast(raw, as: T.self)
    }

    /// Optional per-product array field (e.g. `image_url`): a mismatched-type element becomes `nil`
    /// instead of failing the whole array, and the field is dropped entirely if its length doesn't
    /// match the other parallel arrays (can't be safely indexed by product otherwise).
    fileprivate func optionalArray<T>(_ key: String, count: Int) -> [T?]? {
        guard let raw = self[key] as? [Any], raw.count == count else { return nil }
        return raw.map { $0 as? T }
    }

    /// Event-level metadata, distinct from the per-product metadata array nested in products/discounts.
    fileprivate var ecommerceMetadata: [String: Any]? {
        self[BrazeConstants.Keys.metadata] as? [String: Any]
    }

    /// Optional `type` field. Braze's `typeIdentifiers` is an array, so a scalar (`type:"price_drop"`)
    /// is wrapped into a single-element array rather than dropped.
    fileprivate func typeIdentifiers(_ key: String) -> [String]? {
        if let array = self[key] as? [String] { return array }
        if let scalar = self[key] as? String { return [scalar] }
        return nil
    }

    /// Merges `required` with whichever `optional` entries are non-`nil`, omitting the rest.
    fileprivate static func merging(_ required: [String: Any], ifPresent optional: [String: Any?]) -> [String: Any] {
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

    /// Required currency, uppercased -- Braze validates against ISO-4217 uppercase and would
    /// otherwise reject a common lowercase input like "usd".
    private static func requireCurrency(from payload: [String: Any]) throws -> String {
        try payload.requireNonEmpty(Keys.currency).uppercased()
    }

    // MARK: Product Viewed (single product detail view)

    /// Single product detail view -- scalar fields only, no `products` array.
    static func parseProductViewedEvent(payload: [String: Any]) throws -> Braze.Ecommerce.ProductViewedEvent {
        let productId: String = try payload.require(Keys.productId)
        let productName: String = try payload.require(Keys.productName)
        let variantId: String = try payload.require(Keys.variantId)
        let price: Double = try payload.require(Keys.price)
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)

        return try Braze.Ecommerce.ProductViewedEvent(
            productId: productId,
            productName: productName,
            variantId: variantId,
            imageUrl: payload.optionalValue(Keys.imageUrl),
            productUrl: payload.optionalValue(Keys.productUrl),
            price: price,
            currency: currency,
            source: source,
            metadata: payload.ecommerceMetadata,
            typeIdentifiers: payload.typeIdentifiers(Keys.type))
    }

    // MARK: Cart Updated
    //
    // The caller reads the cart action ("add"/"remove"/"replace") from the payload and picks the
    // matching function below, each returning a concrete type so `logEcommerceEvent`'s generic
    // call is satisfied (an existential `any Braze.Ecommerce.Event` return wouldn't work here).

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
                metadata: payload.ecommerceMetadata)
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
                metadata: payload.ecommerceMetadata)
        }
    }

    static func parseCartUpdatedReplaceEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CartUpdated.Replace {
        // Replace is a full snapshot, so totalValue is required (unlike Add/Remove).
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
                metadata: payload.ecommerceMetadata)
        }
    }

    /// Shared cartId/currency/source/products parsing for the three CartUpdated variants; delegates
    /// SDK construction to `build`.
    private static func parseCartUpdatedEvent<E: Braze.Ecommerce.Event>(
        payload: [String: Any],
        build: (_ cartId: String, _ currency: String, _ source: String, _ products: [Braze.Ecommerce.ProductLineItem]) throws -> E
    ) throws -> E {
        let cartId: String = try payload.require(Keys.cartId)
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)
        let products = try parseProductLineItems(from: payload)
        return try build(cartId, currency, source, products)
    }

    // MARK: Checkout Started / Order Placed

    static func parseCheckoutStartedEvent(payload: [String: Any]) throws -> Braze.Ecommerce.CheckoutStartedEvent {
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)
        let checkoutId: String = try payload.require(Keys.checkoutId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let products = try parseProductLineItems(from: payload)
        return try Braze.Ecommerce.CheckoutStartedEvent(
            checkoutId: checkoutId,
            cartId: payload.optionalValue(Keys.cartId),
            totalValue: totalValue,
            currency: currency,
            subtotalValue: payload.optionalValue(Keys.subtotalValue),
            tax: payload.optionalValue(Keys.tax),
            shipping: payload.optionalValue(Keys.shipping),
            products: products,
            source: source,
            metadata: payload.ecommerceMetadata)
    }

    static func parseOrderPlacedEvent(payload: [String: Any]) throws -> Braze.Ecommerce.OrderPlacedEvent {
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let products = try parseProductLineItems(from: payload)
        return try Braze.Ecommerce.OrderPlacedEvent(
            orderId: orderId,
            cartId: payload.optionalValue(Keys.cartId),
            totalValue: totalValue,
            currency: currency,
            subtotalValue: payload.optionalValue(Keys.subtotalValue),
            tax: payload.optionalValue(Keys.tax),
            shipping: payload.optionalValue(Keys.shipping),
            totalDiscounts: payload.optionalValue(Keys.totalDiscounts),
            discounts: buildDiscountDictionaries(from: payload) as [Any]?,
            products: products,
            source: source,
            metadata: payload.ecommerceMetadata)
    }

    // MARK: Order Cancelled / Refunded (custom events, no typed SDK class)

    static func parseOrderCancelledEvent(payload: [String: Any]) throws -> CustomEvent {
        let orderId = try payload.requireNonEmpty(Keys.orderId)
        let totalValue = try payload.requireAmount(Keys.totalValue)
        let currency = try requireCurrency(from: payload)
        let source = try payload.requireNonEmpty(Keys.source)
        let cancelReason = try payload.requireNonEmpty(Keys.cancelReason)
        let products = try buildProductDictionaries(from: payload)

        let properties = [String: Any].merging(
            [
                Keys.orderId: orderId,
                Keys.totalValue: totalValue,
                Keys.currency: currency,
                Keys.cancelReason: cancelReason,
                Keys.products: products,
                Keys.source: source
            ],
            ifPresent: [
                Keys.subtotalValue: payload.optionalValue(Keys.subtotalValue) as Double?,
                Keys.tax: payload.optionalValue(Keys.tax) as Double?,
                Keys.shipping: payload.optionalValue(Keys.shipping) as Double?,
                Keys.totalDiscounts: payload.optionalValue(Keys.totalDiscounts) as Double?,
                Keys.discounts: buildDiscountDictionaries(from: payload),
                Keys.metadata: payload.ecommerceMetadata
            ])
        return CustomEvent(eventName: BrazeConstants.Ecommerce.eventOrderCancelled, properties: properties)
    }

    static func parseOrderRefundedEvent(payload: [String: Any]) throws -> CustomEvent {
        let orderId = try payload.requireNonEmpty(Keys.orderId)
        // For a partial refund this is the refunded amount, not the original order total.
        let totalValue = try payload.requireAmount(Keys.totalValue)
        let currency = try requireCurrency(from: payload)
        let source = try payload.requireNonEmpty(Keys.source)
        let products = try buildProductDictionaries(from: payload)

        let properties = [String: Any].merging(
            [
                Keys.orderId: orderId,
                Keys.totalValue: totalValue,
                Keys.currency: currency,
                Keys.products: products,
                Keys.source: source
            ],
            ifPresent: [
                Keys.totalDiscounts: payload.optionalValue(Keys.totalDiscounts) as Double?,
                Keys.discounts: buildDiscountDictionaries(from: payload),
                Keys.metadata: payload.ecommerceMetadata
            ])
        return CustomEvent(eventName: BrazeConstants.Ecommerce.eventOrderRefunded, properties: properties)
    }

    // MARK: Shared products/discounts parsing
    //
    // `products` and `discounts` are nested objects holding parallel arrays, zipped by index.
    // Distinct from the top-level event-level `metadata`.

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
        guard let products = payload[Keys.products] as? [String: Any] else {
            throw ParsingError.missingField(Keys.products)
        }
        let productIds: [String] = try products.require(Keys.productId)
        let productNames: [String] = try products.require(Keys.productName)
        let variantIds: [String] = try products.require(Keys.variantId)
        let quantities: [Int] = try products.require(Keys.quantity)
        let prices: [Double] = try products.require(Keys.price)

        let count = productIds.count
        guard productNames.count == count,
              variantIds.count == count,
              quantities.count == count,
              prices.count == count else {
            throw ParsingError.mismatchedArrayLengths(
                fields: [Keys.productId, Keys.productName, Keys.variantId, Keys.quantity, Keys.price])
        }
        return ProductArrays(
            productIds: productIds,
            productNames: productNames,
            variantIds: variantIds,
            quantities: quantities,
            prices: prices,
            imageUrls: products.optionalArray(Keys.imageUrl, count: count),
            productUrls: products.optionalArray(Keys.productUrl, count: count),
            metadatas: products.optionalArray(Keys.metadata, count: count),
            count: count)
    }

    /// A failed `ProductLineItem` build is logged and that product skipped, not propagated --
    /// a per-item failure shouldn't fail the whole parse.
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

    /// Product dicts for the order_cancelled/order_refunded custom-event payload. Each is validated
    /// via `ProductLineItem` (same SDK checks as the typed path); a rejected product is logged and
    /// skipped rather than shipped malformed.
    private static func buildProductDictionaries(from payload: [String: Any]) throws -> [[String: Any]] {
        let arrays = try parseProductArrays(from: payload)
        var products = [[String: Any]]()
        for index in 0..<arrays.count {
            do {
                _ = try Braze.Ecommerce.ProductLineItem(
                    productId: arrays.productIds[index],
                    productName: arrays.productNames[index],
                    variantId: arrays.variantIds[index],
                    imageUrl: arrays.imageUrls?[index],
                    productUrl: arrays.productUrls?[index],
                    quantity: arrays.quantities[index],
                    price: arrays.prices[index],
                    metadata: arrays.metadatas?[index])
            } catch {
                print("*** Tealium Remote Command Error - Braze: skipping invalid product at index \(index): \(error)")
                continue
            }
            let product: [String: Any] = .merging(
                [
                    Keys.productId: arrays.productIds[index],
                    Keys.productName: arrays.productNames[index],
                    Keys.variantId: arrays.variantIds[index],
                    Keys.quantity: arrays.quantities[index],
                    Keys.price: arrays.prices[index]
                ],
                ifPresent: [
                    Keys.imageUrl: arrays.imageUrls?[index],
                    Keys.productUrl: arrays.productUrls?[index],
                    Keys.metadata: arrays.metadatas?[index]
                ])
            products.append(product)
        }
        // Braze requires a non-empty products array; all-rejected would ship empty and get dropped.
        guard !products.isEmpty else {
            throw ParsingError.emptyProducts
        }
        return products
    }

    /// Discounts are optional -- a missing nested object yields an empty list, not a throw.
    private static func parseDiscounts(from payload: [String: Any]) -> [[String: Any]] {
        guard let discounts = payload[Keys.discounts] as? [String: Any] else { return [] }
        let codes = discounts[Keys.discountCode] as? [String] ?? []
        // Braze types discount `amount` as a number (Float), so parse to Double, not String.
        // Per-element (not whole-array) so a mixed array like [10.0, "5"] still recovers both.
        // Uses `map`, not `compactMap`: a dropped entry would shift every later amount onto the
        // wrong code/type, so an unparseable element keeps a nil placeholder instead.
        let amounts: [Double?]
        if let rawAmounts = discounts[Keys.discountAmount] as? [Any] {
            amounts = rawAmounts.map { element -> Double? in
                if element is Bool { return nil }
                if let number = element as? NSNumber, number.doubleValue.isFinite { return number.doubleValue }
                if let string = element as? String, let value = Double(string), value.isFinite { return value }
                return nil
            }
        } else {
            amounts = []
        }
        let types = discounts[Keys.discountType] as? [String] ?? []
        let count = max(codes.count, amounts.count, types.count)

        var result = [[String: Any]]()
        for index in 0..<count {
            var entry = [String: Any]()
            if index < codes.count { entry[Keys.discountCode] = codes[index] }
            if index < amounts.count, let amount = amounts[index] { entry[Keys.discountAmount] = amount }
            if index < types.count { entry[Keys.discountType] = types[index] }
            result.append(entry)
        }
        return result
    }

    /// Same as `parseDiscounts`, but `nil` instead of an empty array so callers can omit the key.
    private static func buildDiscountDictionaries(from payload: [String: Any]) -> [[String: Any]]? {
        let discounts = parseDiscounts(from: payload)
        return discounts.isEmpty ? nil : discounts
    }
}
