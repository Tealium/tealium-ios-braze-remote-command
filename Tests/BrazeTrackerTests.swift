//
//  BrazeTrackerTests.swift
//  RemoteCommandModulesTests
//
//  Created by Jonathan Wong on 11/16/18.
//  Copyright © 2018 Tealium. All rights reserved.
//

import XCTest
@testable import TealiumBraze
@testable import TealiumSwift

class BrazeTrackerTests: XCTestCase {
    
    let brazeTracker = MockBrazeTracker()
    var brazeCommand: BrazeCommand!
    var remoteCommand: TealiumRemoteCommand!
    
    override func setUp() {
        brazeCommand = BrazeCommand(brazeTracker: brazeTracker)
        remoteCommand = brazeCommand.remoteCommand()
    }
    
    override func tearDown() {
        
    }
    
    func testInitializeIsNotCalledWithoutApiKey() {
        let expect = expectation(description: "test initialize")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize",
                                                        ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.initializeBrazeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testInitializeCalledWithApiKey() {
        let expect = expectation(description: "test initialize")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize",
                                                        "api_key": "test123"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.initializeBrazeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testChangeUserIdentifierCalledSuccess() {
        let expect = expectation(description: "test initialize")
        let userIdentifier = "tealium-ios-test-user"
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,useridentifier",
                                                        "user_id": userIdentifier
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.changeUserCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testChangeUserIdentifierNotCalled_userIdentifierKeyMissing() {
        let expect = expectation(description: "test user identifier")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,useridentifier"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.changeUserCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUserAliasNotCalled_keysMissing() {
        let expect = expectation(description: "test user alias not called")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,useralias",
                                      "user_alias": "test_alias"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.addAliasCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUserAliasNotCalledSuccess() {
        let expect = expectation(description: "test user alias called")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,useralias",
                                      "user_alias": "test_alias",
                                      "alias_label": "alias_label"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.addAliasCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogCustomEventSuccess() {
        let expect = expectation(description: "test log event")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,lOGcustomEvent",
                                                        "event_name": "test_event"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.logCustomEventCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogCustomEventNotCalled_logCustomEventNameMissing() {
        let expect = expectation(description: "test log event")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,lOGcustomEvent"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logCustomEventCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogCustomEventSuccess_propertiesMissing() {
        let expect = expectation(description: "test log event without properties")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
                                      "event_name": "test_event",
                                      "properties_key_misnamed": [
                                        "key1": "value1",
                                        "key2": "value2",
                                        "key3": "value3"]]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.logCustomEventCallCount)
                XCTAssertEqual(0, brazeTracker.logCustomEventWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogCustomEventWithProperties() {
        let expect = expectation(description: "test log event with properties")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,lOGcustomEvent",
                                      "event_name": "test_event",
                                      "event_properties": [
                                        "key1": "value1",
                                        "key2": "value2",
                                        "key3": "value3"]]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logCustomEventCallCount)
                XCTAssertEqual(1, brazeTracker.logCustomEventWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUserAttributesSet() {
        let expect = expectation(description: "test user attribute set")
        let dateString = Date().iso8601String
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,useridentifier,userAttribute",
                                                        "first_name": "first_name_test",
                                                        "last_name": "last_name_test",
                                                        "email": "email_test",
                                                        "date_of_birth": "\(dateString)",
                                                        "country": "country_test",
                                                        "language": "language_test",
                                                        "home_city": "home_city_test",
                                                        "phone": "phone_test",
                                                        "avatar_image_url": "avatar_image_url_test",
                                                        "gender": "male"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(10, brazeTracker.setUserAttributeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUserAttributesSetOnlyCallsAppboyUserAttributeKeys() {
        let expect = expectation(description: "test user attribute set")
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       payload: [
                                                        "command_name": "initialize,useridentifier,userAttribute",
                                                        "first_name": "first_name_test",
                                                        "last_name": "last_name_test",
                                                        "email": "email_test",
                                                        "country": "country_test",
                                                        "language": "language_test",
                                                        "home_city": "home_city_test",
                                                        "phone": "phone_test",
                                                        "avatar_image_url": "avatar_image_url_test",
                                                        "not_a_user_attribute_key": "123",
                                                        "not_a_user_attribute_key2": "456"
            ])?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(8, brazeTracker.setUserAttributeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testFacebookUserSet() {
        let expect = expectation(description: "test facebook user set")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,facebookuser",
                                      "facebook_id": [
                                        "user_info": [:],
                                        "friends_count": 100,
                                        "likes": ["apple", "orange"]
                                        ]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.facebookUserCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testTwitterUserSet() {
        let expect = expectation(description: "test twitter user set")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,twitteruser",
                                      "twitter_user": [
                                        "user_info": [:],
                                        "friends_count": 100,
                                        "likes": []
            ]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.twitterUserCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testCustomAttributesSet() {
        let expect = expectation(description: "test custom attribute set")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
                                      "set_custom_attribute": [
                                        "boolkey": false,
                                        "intkey": 1,
                                        "doublekey": 2.0,
                                        "stringkey": "test_string"]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(4, brazeTracker.setCustomAttributeWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testCustomAttributesNotCalled_keyMissing() {
        let expect = expectation(description: "test custom attribute set")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,setcustomattribute",
                                      "boolkey": false,
                                      "intkey": 1,
                                      "doublekey": 2.0,
                                      "stringkey": "test_string"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUnsetCustomAttributesNotCalled_keyMissing() {
        let expect = expectation(description: "test custom attribute unset")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testUnsetCustomAttributesNotCalledSuccess() {
        let expect = expectation(description: "test custom attribute unset")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,unsetcustomattribute",
                                      "unset_custom_attribute": "attribute_key"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.setCustomAttributeWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testIncrementCustomAttributeSuccess() {
        let expect = expectation(description: "test increment custom attribute")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,incrementcustomattribute",
                                      "increment_custom_attribute": ["key1": 1,
                                                              "key2": 2]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(2, brazeTracker.incrementCustomUserAttributeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testCustomArrayAttributeSet() {
        let expect = expectation(description: "test custom array attribute set")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,setcustomarrayattribute",
                                      "set_custom_array_attribute": [
                                        "array_key1": ["value1", "value2", "value3"],
                                        "array_key2": ["value1", "value2", "value3"],
                                        "array_key3": ["value1", "value2", "value3"],
            ]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(3, brazeTracker.setCustomAttributeWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testAddToCustomAttributeArraySuccess() {
        let expect = expectation(description: "test add to custom array attribute")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,appendcustomarrayattribute",
                                      "append_custom_array_attribute": [
                                        "array_key1": "value1",
                                        "array_key2": "value2",
                                        "array_key3": "value3"
            ]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(3, brazeTracker.addToCustomAttributeArrayWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testRemoveCustomAttributeArraySuccess() {
        let expect = expectation(description: "test remove custom array attribute")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,removecustomarrayattribute",
                                      "remove_custom_array_attribute": [
                                        "array_key1": "value1",
                                        "array_key2": "value2",
                                        "array_key3": "value3"
            ]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)

                XCTAssertEqual(3, brazeTracker.removeFromCustomAttributeArrayWithKeyCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testSetEmailNotificationSubscriptionTypeSuccess() {
        let expect = expectation(description: "test set email notification subscription type")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
                                      "email_notification": "optedIn"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testSetEmailNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let expect = expectation(description: "test set email notification subscription type")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,emailnotification",
                                      "email_notification": "UN subscribed"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testSetPushNotificationSubscriptionTypeSuccess() {
        let expect = expectation(description: "test set push notification subscription type")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
                                      "push_notification": "subscribed"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.setPushNotificationSubscriptionTypeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testSetPushNotificationSubscriptionTypeNotCalled_incorrectSubscriptionType() {
        let expect = expectation(description: "test set push notification subscription type")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,pushnotification",
                                      "email_notification": "SUBscribed"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.setEmailNotificationSubscriptionTypeCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseNotCalled_productIdentifierMissing() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "currency": "USD",
                                      "price": 12.34
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseNotCalled_currencyMissing() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": "123",
                                      "price": 12.34
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseNotCalled_priceMissing() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": "123",
                                      "currency": "USD"
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseSuccess() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": ["123"],
                                      "currency": "USD",
                                      "price": [12.34]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(1, brazeTracker.logPurchaseCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseWithQuantitySuccess() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": ["123"],
                                      "currency": "USD",
                                      "price": [12.34],
                                      "quantity": [5]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
                XCTAssertEqual(1, brazeTracker.logPurchaseWithQuantityCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseWithPropertiesSuccess() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": ["123"],
                                      "currency": "USD",
                                      "price": [12.34],
                                      "purchase_properties": ["item1": 123]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
                XCTAssertEqual(1, brazeTracker.logPurchaseWithPropertiesCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
    
    func testLogPurchaseWithPropertiesWithQuantitySuccess() {
        let expect = expectation(description: "test log purchase")
        let config: [String: Any] = ["response_id": "1234"]
        let payload: [String: Any] = ["command_name": "initialize,logpurchase",
                                      "product_id": ["123", "456"],
                                      "currency": "USD",
                                      "price": [12.34, 1.99],
                                      "quantity": [1, 2],
                                      "purchase_properties": ["item1": 123]
        ]
        if let brazeResponse = HttpHelpers.httpRequest(commandId: "braze",
                                                       config: config,
                                                       payload: payload
            )?.description {
            let remoteCommandResponse = TealiumRemoteCommandResponse(urlString: brazeResponse)
            if let response = remoteCommandResponse {
                remoteCommand.remoteCommandCompletion(response)
                
                XCTAssertEqual(0, brazeTracker.logPurchaseCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithQuantityCallCount)
                XCTAssertEqual(0, brazeTracker.logPurchaseWithPropertiesCallCount)
                XCTAssertEqual(1, brazeTracker.logPurchaseWithQuantityWithPropertiesCallCount)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5.0)
    }
}
