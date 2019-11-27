//
//  EventViewController.swift
//  BrazeRemoteCommand
//
//  Created by Jonathan Wong on 5/30/19.
//  Copyright © 2019 Jonathan Wong. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {

    static var arrayCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logEvent(_ sender: UIButton) {
        TealiumHelper.track(title: "log_custom_event", data: ["event_name": "custom_event"])
    }
    
    @IBAction func logEventWithProperties(_ sender: Any) {
        let eventProperties: [String: Any] = [
            "key1": "value1",
            "key2": "value2"]
        TealiumHelper.track(title: "log_custom_event", data: ["event_name": "custom_event_with_properties",
                                                              "event_properties": eventProperties
            ])
    }
    
    @IBAction func setCustomAttributes(_ sender: UIButton) {
        let customAttributes: [String: Any] = ["pet": "cat",
                                "pet_count": 3]
        TealiumHelper.track(title: "custom_attribute", data: customAttributes)
        
        let customArrayAttributes: [String: Any] = ["pet_names": ["Rosia", "Elsa", "Kawai"]]
        TealiumHelper.track(title: "custom_array_attribute", data: customArrayAttributes)
    }
    
    @IBAction func unsetCustomAttributes(_ sender: UIButton) {
        let customAttributes = ["pet_count_unset": "pet_count"]
        TealiumHelper.track(title: "unset_custom_attribute", data: customAttributes)
        
        let removeCustomArrayAttributes = ["pet_names_remove": "Kawai"]
        TealiumHelper.track(title: "remove_custom_array_attribute", data: removeCustomArrayAttributes)
    }
    
    
    @IBAction func incrementCustomAttributes(_ sender: Any) {
        let customAttributes = ["pet_count_increment": 2]
        TealiumHelper.track(title: "increment_custom_attribute", data: customAttributes)
        
        let appendCustomArrayAttributes: [String: Any] = ["pet_names_append": "petname\(EventViewController.arrayCounter)"]
        EventViewController.arrayCounter += 1
        TealiumHelper.track(title: "append_custom_array_attribute", data: appendCustomArrayAttributes)
    }
    
    
    @IBAction func logPurchase(_ sender: Any) {
        var purchaseInfo = [String: Any]()
        purchaseInfo["product_id"] = ["sku123"]
        purchaseInfo["order_currency"] = "usd"
        purchaseInfo["price"] = 1.99
        TealiumHelper.track(title: "log_purchase", data: purchaseInfo)
    }
    
    @IBAction func setLastKnownLocation(sender: UIButton) {
        var locationInfo = [String: Any]()
        locationInfo["latitude"] = 32.715736
        locationInfo["longitude"] = -117.161087
        locationInfo["horizontal_accuracy"] = 99.00
        TealiumHelper.track(title: "set_location", data: locationInfo)
    }
}
