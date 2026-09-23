//
//  BrazeExtensions.swift
//  TealiumBraze
//
//  Created by Enrico Zannini on 04/11/22.
//

import Foundation
import BrazeKit

extension [String: Any] {
    /// Reads `key`, resolving any alias in `BrazeConstants.keyAliases` (first present wins), or
    /// reads directly if none are registered. Resolved on read rather than by rewriting the
    /// payload, so nested dictionaries (e.g. the ecommerce `products` arrays) get the same
    /// alias handling for free.
    func canonicalValue(_ key: String) -> Any? {
        guard let acceptedKeys = BrazeConstants.keyAliases[key] else { return self[key] }
        return acceptedKeys.lazy.compactMap { self[$0] }.first
    }

    /// Casts `raw` to `T`. Falls back to NSNumber-bridging (JS bridge sends native `Int` where a
    /// `Double` is expected) and String→number parsing (data layers often send numbers as strings,
    /// e.g. `price:"19.99"`), per-element for array types. Returns `nil` if no path applies.
    /// Fractional values for Int targets round to nearest.
    func lenientCast<T>(_ raw: Any, as type: T.Type) -> T? {
        if let value = raw as? T { return value }
        if T.self == Double.self { return lenientDouble(raw) as? T }
        if T.self == Int.self { return lenientInt(raw) as? T }
        // Per-element coercion so a mixed array like [59.99, "19.99"] recovers instead of
        // failing a whole-array cast. Any unparseable element rejects the whole array.
        if T.self == [Double].self, let array = raw as? [Any] {
            let doubles = array.compactMap(lenientDouble)
            return doubles.count == array.count ? doubles as? T : nil
        }
        if T.self == [Int].self, let array = raw as? [Any] {
            let ints = array.compactMap(lenientInt)
            return ints.count == array.count ? ints as? T : nil
        }
        return nil
    }

    /// Finite Double from an NSNumber or a numeric String. Bool bridges to NSNumber, so it is
    /// rejected explicitly to keep `price: true` from coercing to 1.0/0.0.
    private func lenientDouble(_ raw: Any) -> Double? {
        if raw is Bool { return nil }
        let value: Double?
        if let number = raw as? NSNumber {
            value = number.doubleValue
        } else if let string = raw as? String {
            value = Double(string)
        } else {
            value = nil
        }
        return value.flatMap { $0.isFinite ? $0 : nil }
    }

    /// Int from an NSNumber or a numeric String. Fractional values round to nearest, halves away
    /// from zero (2.4 -> 2, 2.5 -> 3); NaN, infinite and out-of-Int-range values are rejected instead of
    /// trapping or producing garbage.
    private func lenientInt(_ raw: Any) -> Int? {
        guard let double = lenientDouble(raw) else { return nil }
        return Int(exactly: double.rounded())
    }

    /// Like `require`, but returns `nil` instead of throwing -- for optional numeric fields
    /// (`tax`, `shipping`, `total_value` on add/remove, etc.).
    func optionalValue<T>(_ key: String) -> T? {
        guard let raw = canonicalValue(key) else { return nil }
        return lenientCast(raw, as: T.self)
    }

    /// Optional per-product array field (e.g. `image_url`, `quantity`): an element that `lenientCast`
    /// can't coerce becomes `nil` instead of failing the whole array, and the field is dropped entirely
    /// if its length doesn't match the other parallel arrays (can't be safely indexed by product otherwise).
    /// Resolves key aliases like `require`/`optionalValue`.
    func optionalArray<T>(_ key: String, count: Int) -> [T?]? {
        guard let raw = canonicalValue(key) as? [Any], raw.count == count else { return nil }
        return raw.map { lenientCast($0, as: T.self) }
    }
}

extension Braze.User.SubscriptionState {
    static func from(_ value: String) -> Self? {
        let lowercasedSubscription = value.lowercased()
        if lowercasedSubscription == "optedin" {
            return .optedIn
        } else if lowercasedSubscription == "subscribed" {
            return .subscribed
        } else if lowercasedSubscription == "unsubscribed" {
            return .unsubscribed
        } else {
            return Self(rawValue: value)
        }
    }
}

extension Braze.User.Gender {
    static func from(_ value: String) -> Self {
        let lowercasedGender = value.lowercased()
        if lowercasedGender == "male" {
            return .male
        } else if lowercasedGender == "female" {
            return .female
        } else if lowercasedGender == "other" {
            return .other
        } else if lowercasedGender == "unknown" {
            return .unknown
        } else if lowercasedGender == "notapplicable" || lowercasedGender == "not_applicable" {
            return .notApplicable
        } else {
            return Self(rawValue: value) ?? .preferNotToSay
        }
    }
}

extension Braze.Configuration.DeviceProperty {
    static func from(_ value: String) -> Self? {
        let lowercasedValue = value.lowercased()
        switch lowercasedValue {
        case "model":
            return .model
        case "osversion":
            return .osVersion
        case "resolution":
            return .resolution
        case "timezone":
            return .timeZone
        case "locale":
            return .locale
        case "carrier":
            return .carrier
        case "pushenabled":
            return .pushEnabled
        case "pushauthstatus":
            return .pushAuthStatus
        default:
            return Self(rawValue: value)
        }
    }
}

extension Braze.Configuration.Api.RequestPolicy {
    static func from(_ value: String) -> Self? {
        let lowercasedValue = value.lowercased()
        switch lowercasedValue {
        case "manual":
            return .manual
        case "automatic":
            return .automatic
        default:
            return Self(rawValue: value)
        }
    }
}
