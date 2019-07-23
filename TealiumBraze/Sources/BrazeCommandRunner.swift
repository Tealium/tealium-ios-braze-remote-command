//
//  BrazeCommandRunner.swift
//  RemoteCommandModulesTests
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation
import Appboy_iOS_SDK
import TealiumSwift

protocol TealiumApplication { }
extension UIApplication: TealiumApplication { }

protocol BrazeCommandRunnable {
    
    // MARK: Initialization
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?)
    
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?)
    
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
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, properties: [AnyHashable: Any]?)
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt, properties: [AnyHashable: Any]?)
  
    // MARK: Enabling/Wiping
    func enableSDK(_ enable: Bool)
    
    func wipeData()
}

protocol BrazeCommandNotifier {
    func registerPushToken(_ pushToken: String)
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    
    func pushAuthorization(fromUserNotificationCenter: Bool)
}

struct BrazeCommandRunner: BrazeCommandRunnable, BrazeCommandNotifier {
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?) {
        Appboy.start(withApiKey: apiKey, in: application as? UIApplication ?? UIApplication.shared, withLaunchOptions: launchOptions)
    }
    
    func initializeBraze(apiKey: String, application: TealiumApplication, launchOptions: [AnyHashable: Any]?, appboyOptions: [AnyHashable: Any]?) {
        Appboy.start(withApiKey: apiKey, in: application as? UIApplication ?? UIApplication.shared, withLaunchOptions: launchOptions, withAppboyOptions: appboyOptions)
    }
    
    func changeUser(_ userIdentifier: String) {
        Appboy.sharedInstance()?.changeUser(userIdentifier)
    }
    
    func addAlias(_ aliasName: String, label: String) {
        Appboy.sharedInstance()?.user.addAlias(aliasName, withLabel: label)
    }
    
    func logCustomEvent(eventName: String) {
        Appboy.sharedInstance()?.logCustomEvent(eventName)
    }
    
    func logCustomEvent(_ eventName: String, properties: [AnyHashable: Any]) {
        Appboy.sharedInstance()?.logCustomEvent(eventName, withProperties: properties)
    }
    
    func setUserAttributes(_ attributes: [String : Any]) {
        _ = AppboyUserAttribute.allCases.map {
            guard let value = attributes["\($0.rawValue)"] as? String else {
                return
            }
            setUserAttribute(key: $0, value: value)
        }
    }
    
    func setUserAttribute(key: AppboyUserAttribute, value: String) {
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
    
    func setCustomAttributes(_ attributes: [String : Any]) {
        _ = attributes.map { attribute in
            guard let value = attribute.value as? AnyHashable else {
                return
            }
            setCustomAttributeWithKey(attribute.key, value: value)
        }
    }
    
    func setCustomAttributeWithKey(_ key: String, value: AnyHashable) {
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
    
    func unsetCustomAttributeWithKey(_ key: String) {
        Appboy.sharedInstance()?.user.unsetCustomAttribute(withKey: key)
    }
    
    func incrementCustomUserAttribute(_ key: String, by: Int) {
        Appboy.sharedInstance()?.user.incrementCustomUserAttribute(key, by: by)
    }
    
    func setCustomAttributeArrayWithKey(_ key: String, array: [Any]?) {
        Appboy.sharedInstance()?.user.setCustomAttributeArrayWithKey(key, array: array)
    }
    
    func addToCustomAttributeArrayWithKey(_ key: String, value: String) {
        Appboy.sharedInstance()?.user.addToCustomAttributeArray(withKey: key, value: value)
    }
    
    func removeFromCustomAttributeArrayWithKey(_ key: String, value: String) {
        Appboy.sharedInstance()?.user.removeFromCustomAttributeArray(withKey: key, value: value)
    }
    
    func setFacebookUser(_ user: [String: Any]) {
        guard let userInfo = user[SocialMediaKey.userInfo.rawValue] as? [String: Any],
        let friendsCount = user[SocialMediaKey.friendsCount.rawValue] as? Int else {
            return
        }
        let likes: [Any]? = user[SocialMediaKey.likes.rawValue] as? [Any]
        Appboy.sharedInstance()?.user.facebookUser = ABKFacebookUser(facebookUserDictionary: userInfo, numberOfFriends: friendsCount, likes: likes)
    }
    
    func setTwitterUser(_ user: [String: Any]) {
        let twitterUser = ABKTwitterUser()
        if let userDescription = user[SocialMediaKey.userDescription.rawValue] as? String {
            twitterUser.userDescription = userDescription
        }
        if let twitterName = user[SocialMediaKey.twitterName.rawValue] as? String {
            twitterUser.twitterName = twitterName
        }
        if let profileImageUrl = user[SocialMediaKey.profileImageUrl.rawValue] as? String {
            twitterUser.profileImageUrl = profileImageUrl
        }
        if let screenName = user[SocialMediaKey.screenName.rawValue] as? String {
            twitterUser.screenName = screenName
        }
        if let followersCount = user[SocialMediaKey.followersCount.rawValue] as? Int {
            twitterUser.followersCount = followersCount
        }
        if let friendsCount = user[SocialMediaKey.friendsCount.rawValue] as? Int {
            twitterUser.friendsCount = friendsCount
        }
        if let statusesCount = user[SocialMediaKey.statusesCount.rawValue] as? Int {
            twitterUser.statusesCount = statusesCount
        }
        if let twitterId = user[SocialMediaKey.twitterId.rawValue] as? Int {
            twitterUser.twitterID = twitterId
        }
        Appboy.sharedInstance()?.user.twitterUser = twitterUser
    }
    
    func setEmailNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.optedIn)
        case .subscribed:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.subscribed)
        case .unsubscribed:
            Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(.unsubscribed)
        }
    }
    
    func setPushNotificationSubscriptionType(value: AppboyNotificationSubscription) {
        switch value {
        case .optedIn:
            Appboy.sharedInstance()?.user.setPush(.optedIn)
        case .subscribed:
            Appboy.sharedInstance()?.user.setPush(.subscribed)
        case .unsubscribed:
            Appboy.sharedInstance()?.user.setPush(.unsubscribed)
        }
    }
    
    func incrementCustomUserAttributes(_ attributes: [String: Int]) {
        attributes.forEach { attribute in
            incrementCustomUserAttribute(attribute.key, by: attribute.value)
        }
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price)
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price, withQuantity: quantity)
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, properties: [AnyHashable: Any]?) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price, withProperties: properties)
    }
    
    func logPurchase(_ productIdentifier: String, currency: String, price: NSDecimalNumber, quantity: UInt, properties: [AnyHashable: Any]?) {
        Appboy.sharedInstance()?.logPurchase(productIdentifier, inCurrency: currency, atPrice: price, withQuantity: quantity, andProperties: properties)
    }
    
    func registerPushToken(_ pushToken: String) {
        Appboy.sharedInstance()?.registerPushToken(pushToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Appboy.sharedInstance()?.register(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Appboy.sharedInstance()?.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    func pushAuthorization(fromUserNotificationCenter: Bool) {
        Appboy.sharedInstance()?.pushAuthorization(fromUserNotificationCenter: fromUserNotificationCenter)
    }
    
    func enableSDK(_ enable: Bool) {
        if enable {
            Appboy.requestEnableSDKOnNextAppRun()
        } else {
            Appboy.disableSDK()
        }
    }
    
    func wipeData() {
        Appboy.wipeDataAndDisableForAppRun()
    }
}


