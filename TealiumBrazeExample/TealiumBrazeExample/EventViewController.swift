//
//  EventViewController.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/30/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {

    static var arrayCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logEvent(_ sender: UIButton) {
        TealiumHelper.trackEvent(title: "log_custom_event", data: ["event_name": "custom_event"])
    }
    
    @IBAction func logEventWithProperties(_ sender: Any) {
        TealiumHelper.trackEvent(title: "log_custom_event", data: ["event_name": "level_up", "start_date": "06/14/2020", "high_score": 1200, "current_level": 5])
    }
    
    @IBAction func setCustomAttributes(_ sender: UIButton) {
        let customAttributes: [String: Any] = ["pet": "cat",
                                "pet_count": 3]
        TealiumHelper.trackEvent(title: "custom_attribute", data: customAttributes)
        
        let customArrayAttributes: [String: Any] = ["pet_names": ["Rosia", "Elsa", "Kawai"]]
        TealiumHelper.trackEvent(title: "custom_array_attribute", data: customArrayAttributes)
    }
    
    @IBAction func unsetCustomAttributes(_ sender: UIButton) {
        let customAttributes = ["pet_count_unset": "pet_count"]
        TealiumHelper.trackEvent(title: "unset_custom_attribute", data: customAttributes)
        
        let removeCustomArrayAttributes = ["pet_names_remove": "Kawai"]
        TealiumHelper.trackEvent(title: "remove_custom_array_attribute", data: removeCustomArrayAttributes)
    }
    
    
    @IBAction func incrementCustomAttributes(_ sender: Any) {
        let customAttributes = ["pet_count_increment": 2]
        TealiumHelper.trackEvent(title: "increment_custom_attribute", data: customAttributes)
        
        let appendCustomArrayAttributes: [String: Any] = ["pet_names_append": "petname\(EventViewController.arrayCounter)"]
        EventViewController.arrayCounter += 1
        TealiumHelper.trackEvent(title: "append_custom_array_attribute", data: appendCustomArrayAttributes)
    }
    
    
    @IBAction func logPurchase(_ sender: Any) {
        var purchaseInfo = [String: Any]()
        purchaseInfo["product_id"] = ["sku123", "sku345"]
        purchaseInfo["product_quantity"] = [1, 2]
        purchaseInfo["currency_code"] = "usd"
        purchaseInfo["product_unit_price"] = [1.99, 4.99]
        purchaseInfo["rewards_member"] = true
        purchaseInfo["rewards_points_earned"] = 5035
        purchaseInfo["date_joined_program"] = "01/15/2020"
        TealiumHelper.trackEvent(title: "log_purchase", data: purchaseInfo)
    }
    
    @IBAction func setLastKnownLocation(sender: UIButton) {
        var locationInfo = [String: Any]()
        locationInfo["latitude"] = 32.715736
        locationInfo["longitude"] = -117.161087
        locationInfo["horizontal_accuracy"] = 99.00
        TealiumHelper.trackEvent(title: "set_location", data: locationInfo)
    }
}
