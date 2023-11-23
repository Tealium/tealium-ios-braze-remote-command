//
//  ViewController.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class EngagementViewController: UIViewController {
    @IBOutlet weak var emailSegmentedControl: UISegmentedControl!
    @IBOutlet weak var pushSegmentedControl: UISegmentedControl!
    
    
    var universalData = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onSend(_ sender: Any) {
        var data = [String: Any]()
        
        data["email_subscription"] = emailSubscription()
        data["push_subscription"] = pushSubscription()
        
        TealiumHelper.trackEvent(title: "setengagement", data: data)
    }
    
    private func emailSubscription() -> String {
        guard let emailString = emailSegmentedControl.titleForSegment(at: emailSegmentedControl.selectedSegmentIndex) else {
            return "unsubscribed"
        }
        return emailString
    }
    
    private func pushSubscription() -> String {
        guard let pushString = pushSegmentedControl.titleForSegment(at: pushSegmentedControl.selectedSegmentIndex) else {
            return "unsubscribed"
        }
        return pushString
    }
}

