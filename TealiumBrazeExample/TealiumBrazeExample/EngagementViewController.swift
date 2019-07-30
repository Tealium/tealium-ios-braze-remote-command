//
//  ViewController.swift
//  BrazeRemoteCommand
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Jonathan Wong. All rights reserved.
//

import UIKit

class EngagementViewController: UIViewController {

    @IBOutlet weak var twitterIdTextField: UITextField!
    @IBOutlet weak var facebookUserTextField: UITextField!
    @IBOutlet weak var facebookFriendsTextField: UITextField!
    @IBOutlet weak var emailSegmentedControl: UISegmentedControl!
    @IBOutlet weak var pushSegmentedControl: UISegmentedControl!
    
    
    var universalData = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onSend(_ sender: Any) {
        var data = [String: Any]()
        
        var facebookInfo = [String: Any]()
        facebookInfo["user_info"] = ["username": facebookUserTextField.text]
        if let friendsCount = facebookFriendsTextField.text, let count = Int(friendsCount) {
            data["facebook_friends_count"] = count
        }
        data["facebook_user"] = facebookInfo
        
        data["twitter_id"] = "fattywaffles"
        data["twitter_user_description"] = "awesome engineer"
        
        data["email_subscription"] = emailSubscription()
        data["push_subscription"] = pushSubscription()
        
        TealiumHelper.track(title: "setengagement", data: data)
        TealiumHelper.track(title: "facebook", data: data)
        TealiumHelper.track(title: "twitter", data: data)
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

