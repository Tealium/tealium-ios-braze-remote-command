//
//  ViewController.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

class EngagementViewController: UIViewController {

    @IBOutlet weak var twitterIdTextField: UITextField!
    @IBOutlet weak var twitterNameTextField: UITextField!
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
        
        data["username"] = facebookUserTextField.text ?? ""
        data["twitter_id"] = twitterIdTextField.text ?? ""
        data["twitter_user_description"] = "awesome engineer"
        data["twitter_name"] = twitterNameTextField.text ?? ""
        data["list_of_likes"] = [
            [
              "name": "Bill the Cat",
              "id": "155111347875779",
              "created_time": "2017-06-18T18:21:04+0000"
            ],
            [
              "name": "Calvin and Hobbes",
              "id": "257573197608192",
              "created_time": "2017-06-18T18:21:02+0000"
            ],
            [
              "name": "Berkeley Breathed's Bloom County",
              "id": "108793262484769",
              "created_time": "2017-06-18T18:20:58+0000"
            ]
          ]
        data["email_subscription"] = emailSubscription()
        data["push_subscription"] = pushSubscription()
        
        TealiumHelper.trackEvent(title: "setengagement", data: data)
        TealiumHelper.trackEvent(title: "facebook", data: data)
        TealiumHelper.trackEvent(title: "twitter", data: data)
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

