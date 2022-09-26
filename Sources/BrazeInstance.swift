//
//  BrazeInstance.swift
//  TealiumBraze
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation

#if SWIFT_PACKAGE
    import AppboyUI
#else
//    import Appboy_iOS_SDK
    import BrazeKit
    import BrazeLocation
#endif

#if COCOAPODS
import TealiumSwift
#else
import TealiumCore
import TealiumRemoteCommands
#endif


public protocol TealiumApplication { }
extension UIApplication: TealiumApplication { }

public protocol BrazeCommand {
    
    var braze: Braze? { get }

    // MARK: Initialization
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?)
    
    // MARK: Geofences
    func logSingleLocation()
    
    // MARK: User IDs
    func changeUser(_ userIdentifier: String)
    
    func addAlias(_ aliasName: String, label: String)
    
    // MARK: Events
    func logCustomEvent(eventName: String)
    
    func logCustomEvent(_ eventName: String, properties: [String: Any])
    
    // MARK: Attributes
    func setUserAttribute(key: AppboyUserAttribute, value: String)
    
    func setUserAttributes(_ attributes: [String: Any])
    
    func setCustomAttributes(_ attributes: [String: Any])
    
    func setCustomAttributeWithKey(_ key: String, value: AnyHashable)
    
    func unsetCustomAttributeWithKey(_ key: String)
    
    func incrementCustomUserAttributes(_ attributes: [String: Int])
    
    func incrementCustomUserAttribute(_ key: String, by: Int)
    
    // MARK: Social Media
    func setFacebookUser(_ user: [String: Any])
    
    func setTwitterUser(_ user:[String: Any])
    
    // MARK: Array Attributes
    func setCustomAttributeArrayWithKey(_ key: String, array: [String]?)
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String)
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String)
    
    // MARK: Subscriptions
    func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    // MARK: Purchases
    func logPurchase(_ productIdentifier: String, currency: String, price: Double)
    
    func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: Double,
                     properties: [String: Any]?)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: Double,
                     quantity: Int,
                     properties: [String: Any]?)
    
    // MARK: Location
    func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double)

    func setLastKnownLocationWithLatitude(latitude: Double,
                                          longitude: Double,
                                          horizontalAccuracy: Double,
                                          altitude: Double,
                                          verticalAccuracy: Double)
    
    // MARK: Enabling/Wiping
    func enableSDK(_ enable: Bool)
    
    func wipeData()
}

public protocol BrazeCommandNotifier {
    func registerDeviceToken(_ deviceToken: Data)
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    
    func pushAuthorization(fromUserNotificationCenter: Bool)
}

public class BrazeInstance: BrazeCommand, BrazeCommandNotifier {
    public var braze: Braze?
    public init() { }
    
    public func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?) {
        var config = Braze.Configuration(apiKey: apiKey, endpoint: "") // TODO: endpoint
        config.location.brazeLocation = BrazeLocation()
        braze = Braze(configuration: config)
//        DispatchQueue.main.async {
//            Appboy.start(withApiKey: apiKey, in: application as? UIApplication ?? UIApplication.shared, withLaunchOptions: launchOptions, withAppboyOptions: appboyOptions)
//            Appboy.sharedInstance()?.addSdkMetadata([.tealium])
//        }
    }
    
    public func logSingleLocation() {
        // TODO: location
//           Appboy.sharedInstance()?.locationManager.logSingleLocation()
    }
    
    public func changeUser(_ userIdentifier: String) {
        braze?.changeUser(userId: userIdentifier, sdkAuthSignature: nil) // TODO: sdkAuthSignature
//        Appboy.sharedInstance()?.changeUser(userIdentifier)
    }
    
    public func addAlias(_ aliasName: String, label: String) {
        braze?.user.add(alias: aliasName, label: label)
//        Appboy.sharedInstance()?.user.addAlias(aliasName, withLabel: label)
    }
    
    public func logCustomEvent(eventName: String) {
        braze?.logCustomEvent(name: eventName)
//        Appboy.sharedInstance()?.logCustomEvent(eventName)
    }
    
    public func logCustomEvent(_ eventName: String, properties: [String: Any]) {
        braze?.logCustomEvent(name: eventName, properties: properties)
//        Appboy.sharedInstance()?.logCustomEvent(eventName, withProperties: properties)
    }
    
    public func setUserAttributes(_ attributes: [String : Any]) {
        AppboyUserAttribute.allCases.forEach {
            guard let value = attributes["\($0.rawValue)"] as? String else {
                return
            }
            setUserAttribute(key: $0, value: value)
        }
    }
    
    public func setUserAttribute(key: AppboyUserAttribute, value: String) {
        switch key {
        case .firstName:
            braze?.user.set(firstName: value)
//            Appboy.sharedInstance()?.user.firstName = value
        case .lastName:
            braze?.user.set(lastName: value)
//            Appboy.sharedInstance()?.user.lastName = value
        case .email:
            braze?.user.set(email: value)
//            Appboy.sharedInstance()?.user.email = value
        case .dateOfBirth:
            guard let date = DateConverter.shared.iso8601DateFormatter.date(from: value) else {
                return
            }
            braze?.user.set(dateOfBirth: date)
//            Appboy.sharedInstance()?.user.dateOfBirth = date
        case .country:
            braze?.user.set(country: value)
//            Appboy.sharedInstance()?.user.country = value
        case .language:
            braze?.user.set(language: value)
//            Appboy.sharedInstance()?.user.language = value
        case .homeCity:
            braze?.user.set(homeCity: value)
//            Appboy.sharedInstance()?.user.homeCity = value
        case .phone:
            braze?.user.set(phoneNumber: value)
//            Appboy.sharedInstance()?.user.phone = value
        case .avatarImageURL:
            break
            // TODO: avatarImageURL
//            Appboy.sharedInstance()?.user.avatarImageURL = value
        case .gender:
            guard let type = AppboyUserGenderType(rawValue: 1), // TODO: type has changed to string!
                let gender = Braze.User.Gender(rawValue: "\(type.rawValue)") else {
                return
            }
            braze?.user.set(gender: gender)
//            Appboy.sharedInstance()?.user.setGender(gender)
        }
    }
    
    public func setCustomAttributes(_ attributes: [String : Any]) {
        _ = attributes.map { attribute in
            guard let value = attribute.value as? AnyHashable else {
                return
            }
            setCustomAttributeWithKey(attribute.key, value: value)
        }
    }
    
    public func setCustomAttributeWithKey(_ key: String, value: AnyHashable) {
        if let value = value as? Bool {
            braze?.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andBOOLValue: value)
        } else if let value = value as? Int {
            braze?.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andIntegerValue: value)
        } else if let value = value as? Double {
            braze?.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDoubleValue: value)
        } else if let value = value as? String {
            braze?.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andStringValue: value)
        } else if let value = value as? Date {
            braze?.user.setCustomAttribute(key: key, value: value)
//            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDateValue: value)
        }
    }
    
    public func unsetCustomAttributeWithKey(_ key: String) {
        braze?.user.unsetCustomAttribute(key: key)
//        Appboy.sharedInstance()?.user.unsetCustomAttribute(withKey: key)
    }
    
    public func incrementCustomUserAttribute(_ key: String, by: Int) {
        braze?.user.incrementCustomUserAttribute(key: key, by: by)
//        Appboy.sharedInstance()?.user.incrementCustomUserAttribute(key, by: by)
    }
    
    public func setCustomAttributeArrayWithKey(_ key: String, array: [String]?) {
        braze?.user.setCustomAttributeArray(key: key, array: array)
//        Appboy.sharedInstance()?.user.setCustomAttributeArrayWithKey(key, array: array)
    }
    
    public func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        braze?.user.addToCustomAttributeArray(key: key, value: value)
//        Appboy.sharedInstance()?.user.addToCustomAttributeArray(withKey: key, value: value)
    }
    
    public func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        braze?.user.removeFromCustomAttributeArray(key: key, value: value)
//        Appboy.sharedInstance()?.user.removeFromCustomAttributeArray(withKey: key, value: value)
    }
    
    public func setFacebookUser(_ user: [String: Any]) {
        guard let userInfo = user[BrazeConstants.SocialMedia.userInfo] as? [String: Any],
            let friendsCount = user[BrazeConstants.SocialMedia.friendsCount] as? Int else {
                return
        }
        let likes: [Any]? = user[BrazeConstants.SocialMedia.likes] as? [Any]
        // TODO: Facebook user
//        Appboy.sharedInstance()?.user.facebookUser = ABKFacebookUser(facebookUserDictionary: userInfo, numberOfFriends: friendsCount, likes: likes)
    }
    
    public func setTwitterUser(_ user: [String: Any]) {
//        let twitterUser = ABKTwitterUser()
//        if let userDescription = user[BrazeConstants.SocialMedia.userDescription] as? String {
//            twitterUser.userDescription = userDescription
//        }
//        if let twitterName = user[BrazeConstants.SocialMedia.twitterName] as? String {
//            twitterUser.twitterName = twitterName
//        }
//        if let profileImageUrl = user[BrazeConstants.SocialMedia.profileImageUrl] as? String {
//            twitterUser.profileImageUrl = profileImageUrl
//        }
//        if let screenName = user[BrazeConstants.SocialMedia.screenName] as? String {
//            twitterUser.screenName = screenName
//        }
//        if let followersCount = user[BrazeConstants.SocialMedia.followersCount] as? Int {
//            twitterUser.followersCount = followersCount
//        }
//        if let friendsCount = user[BrazeConstants.SocialMedia.friendsCount] as? Int {
//            twitterUser.friendsCount = friendsCount
//        }
//        if let statusesCount = user[BrazeConstants.SocialMedia.statusesCount] as? Int {
//            twitterUser.statusesCount = statusesCount
//        }
//        if let twitterId = user[BrazeConstants.SocialMedia.twitterId] as? Int {
//            twitterUser.twitterID = twitterId
//        }
        // TODO: Twitter
//        Appboy.sharedInstance()?.user.twitterUser = twitterUser
    }
    
    public func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            braze?.user.set(emailSubscriptionState: .optedIn)
//            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.optedIn)
        case .subscribed:
            braze?.user.set(emailSubscriptionState: .subscribed)
//            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.subscribed)
        case .unsubscribed:
            braze?.user.set(emailSubscriptionState: .unsubscribed)
//            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.unsubscribed)
        }
    }
    
    public func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            braze?.user.set(pushNotificationSubscriptionState: .optedIn)
//            Appboy.sharedInstance()?.user.setPush(.optedIn)
        case .subscribed:
            braze?.user.set(pushNotificationSubscriptionState: .subscribed)
//            Appboy.sharedInstance()?.user.setPush(.subscribed)
        case .unsubscribed:
            braze?.user.set(pushNotificationSubscriptionState: .unsubscribed)
//            Appboy.sharedInstance()?.user.setPush(.unsubscribed)
        }
    }
    
    public func incrementCustomUserAttributes(_ attributes: [String: Int]) {
        attributes.forEach { attribute in
            incrementCustomUserAttribute(attribute.key, by: attribute.value)
        }
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: Double) {
        braze?.logPurchase(productId: productIdentifier, currency: currency, price: price)
//        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price)
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: Double, quantity: Int) {
        braze?.logPurchase(productId: productIdentifier, currency: currency, price: price, quantity: quantity)
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: Double,
                            properties: [String: Any]?) {
        braze?.logPurchase(productId: productIdentifier, currency: currency, price: price, properties: properties)
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: Double,
                            quantity: Int,
                            properties: [String: Any]?) {
        braze?.logPurchase(productId: productIdentifier, currency: currency, price: price, quantity: quantity, properties: properties)
//        Appboy.sharedInstance()?.logPurchase(productIdentifier,
//                                             inCurrency: currency,
//                                             atPrice: price,
//                                             withQuantity: quantity,
//                                             andProperties: properties)
    }
    
    public func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double) {
        braze?.user.setLastKnownLocation(latitude: latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy)
//        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy)
    }

    public func setLastKnownLocationWithLatitude(latitude: Double,
                                                 longitude: Double,
                                                 horizontalAccuracy: Double,
                                                 altitude: Double,
                                                 verticalAccuracy: Double) {
        braze?.user.setLastKnownLocation(latitude: latitude, longitude: longitude, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy)
//        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude,
//                                                                       longitude: longitude,
//                                                                       horizontalAccuracy: horizontalAccuracy,
//                                                                       altitude: altitude,
//                                                                       verticalAccuracy: verticalAccuracy)
    }
    
    public func registerDeviceToken(_ deviceToken: Data) {
        braze?.notifications.register(deviceToken: deviceToken)
//        Appboy.sharedInstance()?.registerDeviceToken(deviceToken)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // TODO: didReceiveRemoteNotifiaction?
        
//        Appboy.sharedInstance()?.register(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    // TODO: background notification - braze?.notifications.handleBackgroundNotification(userInfo:, fetchCompletionHandler:)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        braze?.notifications.handleUserNotification(response: response, withCompletionHandler: completionHandler)
//        Appboy.sharedInstance()?.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    public func pushAuthorization(fromUserNotificationCenter: Bool) {
        // TODO: push authorization
//        Appboy.sharedInstance()?.pushAuthorization(fromUserNotificationCenter: fromUserNotificationCenter)
    }
    
    public func enableSDK(_ enable: Bool) {
        braze?.enabled = enable
//        if enable {
//            Appboy.requestEnableSDKOnNextAppRun()
//        } else {
//            Appboy.disableSDK()
//        }
    }
    
    public func wipeData() {
        braze?.wipeData()
//        Appboy.wipeDataAndDisableForAppRun()
    }
}

