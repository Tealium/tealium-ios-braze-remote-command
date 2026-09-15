//
//  BrazeExtensions.swift
//  TealiumBraze
//
//  Created by Enrico Zannini on 04/11/22.
//

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
