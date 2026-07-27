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

    /// Casts `raw` to `T`, falling back to NSNumber-bridging for `Double`/`Int`/`[Double]`/`[Int]`
    /// when a direct cast fails (native `Int` payloads from the JS bridge fail a direct `as? Double`
    /// cast; routing through `NSNumber` recovers them), then to String→number parsing for the same
    /// target types. Tealium data layers routinely send numbers as strings (e.g. `total_value:"99.99"`
    /// or `price:["10","20"]`); without the String fallbacks these would throw `typeMismatch` and drop
    /// the whole event, whereas Android coerces them. Returns `nil` when no cast applies.
    private func lenientCast<T>(_ raw: Any, as type: T.Type) -> T? {
        if let value = raw as? T { return value }
        if T.self == Double.self {
            if let number = raw as? NSNumber { return number.doubleValue as? T }
            if let string = raw as? String, let value = Double(string) { return value as? T }
        }
        if T.self == Int.self {
            if let number = raw as? NSNumber { return number.intValue as? T }
            if let string = raw as? String, let value = Int(string) { return value as? T }
        }
        if T.self == [Double].self {
            // Coerce element-by-element (not all-or-nothing) so a mixed array like `[59.99, "19.99"]`
            // -- which matches neither `[NSNumber]` nor `[String]` as a whole -- is still recovered,
            // matching Android's per-element coercion. Return nil if ANY element is unparseable,
            // preserving the "reject on any unparseable" contract.
            if let array = raw as? [Any] {
                var doubles = [Double]()
                for element in array {
                    if let number = element as? NSNumber {
                        doubles.append(number.doubleValue)
                    } else if let string = element as? String, let value = Double(string) {
                        doubles.append(value)
                    } else {
                        return nil
                    }
                }
                return doubles as? T
            }
        }
        if T.self == [Int].self {
            // Same per-element coercion as `[Double]` above (e.g. `[1, "2"]`), rejecting the whole
            // array if any element is unparseable.
            if let array = raw as? [Any] {
                var ints = [Int]()
                for element in array {
                    if let number = element as? NSNumber {
                        ints.append(number.intValue)
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

    /// Reads a required field as `T`, using `lenientCast`'s NSNumber-bridging. Throws
    /// `missingField` when absent, `typeMismatch` when present but not coercible to `T`.
    func require<T>(_ key: String, fallbackKey: String? = nil) throws -> T {
        guard let raw = get(key: key, fallbackKey: fallbackKey) else {
            throw ParsingError.missingField(fallbackKey.map { "\(key) or \($0)" } ?? key)
        }
        guard let value: T = lenientCast(raw, as: T.self) else {
            throw ParsingError.typeMismatch(
                field: key, expected: String(describing: T.self), actual: String(describing: Swift.type(of: raw)))
        }
        return value
    }

    /// Same NSNumber-bridging as `require<T>`, but returns `nil` instead of throwing when the key
    /// is absent or the value can't be coerced to `T`. Use for genuinely optional numeric fields
    /// (`total_value` on add/remove, `tax`, `shipping`, etc.).
    func optionalValue<T>(_ key: String) -> T? {
        guard let raw = self[key] else { return nil }
        return lenientCast(raw, as: T.self)
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

    /// Optional event-level custom metadata, shared by every ecommerce event under the same key.
    /// Distinct from the nested `products`/`discounts` per-item metadata array.
    var ecommerceMetadata: [String: Any]? {
        self[BrazeConstants.Ecommerce.metadata] as? [String: Any]
    }

    /// Reads the optional `type` (typeIdentifiers) field, accepting either a `[String]` or a single
    /// scalar `String`. Braze's `typeIdentifiers` is an array, so a scalar value (e.g.
    /// `type:"price_drop"`) is wrapped into a single-element array rather than silently dropped.
    func typeIdentifiers(_ key: String) -> [String]? {
        if let array = self[key] as? [String] { return array }
        if let scalar = self[key] as? String { return [scalar] }
        return nil
    }

    /// Merges `required` with whichever `optional` entries are non-`nil`, omitting the rest.
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
    typealias Keys = BrazeConstants.Ecommerce

    /// Reads the required `currency` field and normalizes it to uppercase. Braze validates currency
    /// against ISO-4217 canonical uppercase, so a common lowercase input like `"usd"` would throw on
    /// event construction and silently drop the whole event. Uppercasing here accepts that input.
    private static func requireCurrency(from payload: [String: Any]) throws -> String {
        let currency: String = try payload.require(Keys.currency)
        return currency.uppercased()
    }

    // MARK: Product Viewed (single product detail view)

    /// `logProductViewed` targets a single product detail view, so every product field is a plain
    /// scalar. Unlike cart/checkout/order, this event carries no `products` object -- an array
    /// value is a caller mistake and fails validation (`require` throws) rather than being coerced.
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

    // MARK: Cart Updated (single command, action read from payload)
    //
    // `logcartupdated` is a single command; the cart action ("add"/"remove"/"replace") is read
    // from the payload's `action` key rather than being implied by the command name (unlike the
    // old 3-command design). Each typed variant is parsed by its own function so the caller
    // (BrazeRemoteCommand) can dispatch to `logEcommerceEvent` with a concrete type -- an
    // existential `any Braze.Ecommerce.Event` return here wouldn't satisfy that generic call.

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
                metadata: payload.ecommerceMetadata)
        }
    }

    /// Shared guard for the three `CartUpdated` variants: cartId, currency, source, and a valid
    /// product list. Delegates SDK construction to `build`.
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
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)
        let cancelReason: String = try payload.require(Keys.cancelReason)
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
        return CustomEvent(eventName: "ecommerce.order_cancelled", properties: properties)
    }

    static func parseOrderRefundedEvent(payload: [String: Any]) throws -> CustomEvent {
        let orderId: String = try payload.require(Keys.orderId)
        let totalValue: Double = try payload.require(Keys.totalValue)
        let currency = try requireCurrency(from: payload)
        let source: String = try payload.require(Keys.source)
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
        return CustomEvent(eventName: "ecommerce.order_refunded", properties: properties)
    }

    // MARK: Shared products/discounts parsing (nested-parallel-arrays convention)
    //
    // `products` and `discounts` are nested objects holding PARALLEL ARRAYS, zipped by index --
    // unifying the shape with tealium-android-firebase-remote-command's items_params convention.
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

    /// Builds the plain product dictionaries for the order_cancelled/order_refunded custom-event
    /// wire payload. Each product is first validated by constructing a `ProductLineItem` (the same
    /// SDK validation the typed cart/checkout/order path uses); a product the SDK rejects (negative
    /// price, blank/over-length string, negative quantity) is logged and skipped rather than emitting
    /// a malformed line item on the wire.
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
        return products
    }

    /// Discounts are entirely optional (unlike products); a missing/absent nested object yields
    /// an empty list rather than throwing.
    private static func parseDiscounts(from payload: [String: Any]) -> [[String: Any]] {
        guard let discounts = payload[Keys.discounts] as? [String: Any] else { return [] }
        let codes = discounts[Keys.discountCode] as? [String] ?? []
        // The Braze "Log eCommerce events" doc types the discount `amount` as a Float (JSON number),
        // so emit each amount as a `Double` (number), not a String. These entries are passed as plain
        // dictionaries to both the typed OrderPlacedEvent (`discounts: [Any]?` pass-through) and the
        // raw order_cancelled/order_refunded custom-event JSON, so a numeric value matches the wire
        // schema. Accepts stringy input (`["10.0","5"]`), native `[Double]`, and `[NSNumber]`, parsing
        // each element to Double.
        let amounts: [Double]
        if let strings = discounts[Keys.discountAmount] as? [String] {
            amounts = strings.compactMap { Double($0) }
        } else {
            amounts = discounts[Keys.discountAmount] as? [Double]
                ?? (discounts[Keys.discountAmount] as? [NSNumber])?.map { $0.doubleValue }
                ?? []
        }
        let types = discounts[Keys.discountType] as? [String] ?? []
        let count = max(codes.count, amounts.count, types.count)

        var result = [[String: Any]]()
        for index in 0..<count {
            var entry = [String: Any]()
            if index < codes.count { entry[Keys.discountCode] = codes[index] }
            if index < amounts.count { entry[Keys.discountAmount] = amounts[index] }
            if index < types.count { entry[Keys.discountType] = types[index] }
            result.append(entry)
        }
        return result
    }

    /// Same as `parseDiscounts`, but returns `nil` (rather than an empty array) when there are no
    /// discounts, so callers can omit the key entirely from the wire payload.
    private static func buildDiscountDictionaries(from payload: [String: Any]) -> [[String: Any]]? {
        let discounts = parseDiscounts(from: payload)
        return discounts.isEmpty ? nil : discounts
    }
}
