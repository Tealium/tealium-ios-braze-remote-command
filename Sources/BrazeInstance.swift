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
    import Appboy_iOS_SDK
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
    
    // MARK: Initialization
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?)
    
    // MARK: Geofences
    func logSingleLocation()
    
    // MARK: User IDs
    func changeUser(_ userIdentifier: String)
    
    func addAlias(_ aliasName: String, label: String)
    
    // MARK: Events
    func logCustomEvent(eventName: String)
    
    func logCustomEvent(_ eventName: String, properties: [AnyHashable: Any])
    
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
    func setCustomAttributeArrayWithKey(_ key: String, array: [Any]?)
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String)
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String)
    
    // MARK: Subscriptions
    func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription)
    
    // MARK: Purchases
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber)
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: NSDecimalNumber,
                     properties: [AnyHashable: Any]?)
    
    func logPurchase(_ productIdentifier: String,
                     currency: String,
                     price: NSDecimalNumber,
                     quantity: UInt,
                     properties: [AnyHashable: Any]?)
    
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
    
    public init() { }
    
    public func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            Appboy.start(withApiKey: apiKey, in: application as? UIApplication ?? UIApplication.shared, withLaunchOptions: launchOptions, withAppboyOptions: appboyOptions)
            Appboy.sharedInstance()?.addSdkMetadata([.tealium])
        }
    }
    
    public func logSingleLocation() {
           Appboy.sharedInstance()?.locationManager.logSingleLocation()
    }
    
    public func changeUser(_ userIdentifier: String) {
        Appboy.sharedInstance()?.changeUser(userIdentifier)
    }
    
    public func addAlias(_ aliasName: String, label: String) {
        Appboy.sharedInstance()?.user.addAlias(aliasName, withLabel: label)
    }
    
    public func logCustomEvent(eventName: String) {
        Appboy.sharedInstance()?.logCustomEvent(eventName)
    }
    
    public func logCustomEvent(_ eventName: String, properties: [AnyHashable: Any]) {
        Appboy.sharedInstance()?.logCustomEvent(eventName, withProperties: properties)
    }
    
    public func setUserAttributes(_ attributes: [String : Any]) {
        _ = AppboyUserAttribute.allCases.map {
            guard let value = attributes["\($0.rawValue)"] as? String else {
                return
            }
            setUserAttribute(key: $0, value: value)
        }
    }
    
    public func setUserAttribute(key: AppboyUserAttribute, value: String) {
        switch key {
        case .firstName:
            Appboy.sharedInstance()?.user.firstName = value
        case .lastName:
            Appboy.sharedInstance()?.user.lastName = value
        case .email:
            Appboy.sharedInstance()?.user.email = value
        case .dateOfBirth:
            guard let date = DateConverter.shared.iso8601DateFormatter.date(from: value) else {
                return
            }
            Appboy.sharedInstance()?.user.dateOfBirth = date
        case .country:
            Appboy.sharedInstance()?.user.country = value
        case .language:
            Appboy.sharedInstance()?.user.language = value
        case .homeCity:
            Appboy.sharedInstance()?.user.homeCity = value
        case .phone:
            Appboy.sharedInstance()?.user.phone = value
        case .avatarImageURL:
            Appboy.sharedInstance()?.user.avatarImageURL = value
        case .gender:
            guard let gender = ABKUserGenderType(rawValue: AppboyUserGenderType.from(value).rawValue) else {
                return
            }
            Appboy.sharedInstance()?.user.setGender(gender)
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
            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andBOOLValue: value)
        } else if let value = value as? Int {
            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andIntegerValue: value)
        } else if let value = value as? Double {
            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDoubleValue: value)
        } else if let value = value as? String {
            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andStringValue: value)
        } else if let value = value as? Date {
            Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDateValue: value)
        }
    }
    
    public func unsetCustomAttributeWithKey(_ key: String) {
        Appboy.sharedInstance()?.user.unsetCustomAttribute(withKey: key)
    }
    
    public func incrementCustomUserAttribute(_ key: String, by: Int) {
        Appboy.sharedInstance()?.user.incrementCustomUserAttribute(key, by: by)
    }
    
    public func setCustomAttributeArrayWithKey(_ key: String, array: [Any]?) {
        Appboy.sharedInstance()?.user.setCustomAttributeArrayWithKey(key, array: array)
    }
    
    public func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        Appboy.sharedInstance()?.user.addToCustomAttributeArray(withKey: key, value: value)
    }
    
    public func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        Appboy.sharedInstance()?.user.removeFromCustomAttributeArray(withKey: key, value: value)
    }
    
    public func setFacebookUser(_ user: [String: Any]) {
        guard let userInfo = user[BrazeConstants.SocialMedia.userInfo] as? [String: Any],
            let friendsCount = user[BrazeConstants.SocialMedia.friendsCount] as? Int else {
                return
        }
        let likes: [Any]? = user[BrazeConstants.SocialMedia.likes] as? [Any]
        Appboy.sharedInstance()?.user.facebookUser = ABKFacebookUser(facebookUserDictionary: userInfo, numberOfFriends: friendsCount, likes: likes)
    }
    
    public func setTwitterUser(_ user: [String: Any]) {
        let twitterUser = ABKTwitterUser()
        if let userDescription = user[BrazeConstants.SocialMedia.userDescription] as? String {
            twitterUser.userDescription = userDescription
        }
        if let twitterName = user[BrazeConstants.SocialMedia.twitterName] as? String {
            twitterUser.twitterName = twitterName
        }
        if let profileImageUrl = user[BrazeConstants.SocialMedia.profileImageUrl] as? String {
            twitterUser.profileImageUrl = profileImageUrl
        }
        if let screenName = user[BrazeConstants.SocialMedia.screenName] as? String {
            twitterUser.screenName = screenName
        }
        if let followersCount = user[BrazeConstants.SocialMedia.followersCount] as? Int {
            twitterUser.followersCount = followersCount
        }
        if let friendsCount = user[BrazeConstants.SocialMedia.friendsCount] as? Int {
            twitterUser.friendsCount = friendsCount
        }
        if let statusesCount = user[BrazeConstants.SocialMedia.statusesCount] as? Int {
            twitterUser.statusesCount = statusesCount
        }
        if let twitterId = user[BrazeConstants.SocialMedia.twitterId] as? Int {
            twitterUser.twitterID = twitterId
        }
        Appboy.sharedInstance()?.user.twitterUser = twitterUser
    }
    
    public func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.optedIn)
        case .subscribed:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.subscribed)
        case .unsubscribed:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.unsubscribed)
        }
    }
    
    public func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            Appboy.sharedInstance()?.user.setPush(.optedIn)
        case .subscribed:
            Appboy.sharedInstance()?.user.setPush(.subscribed)
        case .unsubscribed:
            Appboy.sharedInstance()?.user.setPush(.unsubscribed)
        }
    }
    
    public func incrementCustomUserAttributes(_ attributes: [String: Int]) {
        attributes.forEach { attribute in
            incrementCustomUserAttribute(attribute.key, by: attribute.value)
        }
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price)
    }
    
    public func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price, withQuantity: quantity)
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: NSDecimalNumber,
                            properties: [AnyHashable: Any]?) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier,
                                             inCurrency: currency,
                                             atPrice: price,
                                             withProperties: properties)
    }
    
    public func logPurchase(_ productIdentifier: String,
                            currency: String,
                            price: NSDecimalNumber,
                            quantity: UInt,
                            properties: [AnyHashable: Any]?) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier,
                                             inCurrency: currency,
                                             atPrice: price,
                                             withQuantity: quantity,
                                             andProperties: properties)
    }
    
    public func setLastKnownLocationWithLatitude(latitude: Double, longitude: Double, horizontalAccuracy: Double) {
        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude, longitude: longitude, horizontalAccuracy: horizontalAccuracy)
    }

    public func setLastKnownLocationWithLatitude(latitude: Double,
                                                 longitude: Double,
                                                 horizontalAccuracy: Double,
                                                 altitude: Double,
                                                 verticalAccuracy: Double) {
        Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(latitude,
                                                                       longitude: longitude,
                                                                       horizontalAccuracy: horizontalAccuracy,
                                                                       altitude: altitude,
                                                                       verticalAccuracy: verticalAccuracy)
    }
    
    public func registerDeviceToken(_ deviceToken: Data) {
        Appboy.sharedInstance()?.registerDeviceToken(deviceToken)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Appboy.sharedInstance()?.register(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Appboy.sharedInstance()?.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    public func pushAuthorization(fromUserNotificationCenter: Bool) {
        Appboy.sharedInstance()?.pushAuthorization(fromUserNotificationCenter: fromUserNotificationCenter)
    }
    
    public func enableSDK(_ enable: Bool) {
        if enable {
            Appboy.requestEnableSDKOnNextAppRun()
        } else {
            Appboy.disableSDK()
        }
    }
    
    public func wipeData() {
        Appboy.wipeDataAndDisableForAppRun()
    }
}

