//
//  UserViewController.swift
//  BrazeRemoteCommand
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Jonathan Wong. All rights reserved.
//

import UIKit

class UserViewController: UIViewController {

    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var userAliasTextField: UITextField!
    @IBOutlet weak var userLabelTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var homeCityTextField: UITextField!
    @IBOutlet weak var avatarImageURLTextField: UITextField!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        genderSegmentedControl.selectedSegmentIndex = 3
        
        TealiumHelper.track(title: "user_alias", data: nil)
    }
    
    @IBAction func onSend( _ sender: UIButton) {
        var data = [String: Any]()
        data["first_name"] = firstNameTextField.text
        data["last_name"] = lastNameTextField.text
        data["email"] = emailTextField.text
        data["gender"] = gender()
        data["home_city"] = homeCityTextField.text
        
        if let birthday = DateConverter.shared.dobDateFormatter.date(from: birthdayTextField.text!) {
            let isoBirthday = DateConverter.shared.iso8601DateFormatter.string(from: birthday)
            data["birthday"] = isoBirthday
        }
        data["user_id"] = usernameTextField.text
        data["user_alias"] = userAliasTextField.text
        data["alias_label"] = userLabelTextField.text
        
        TealiumHelper.track(title: "user_attribute", data: data)
        TealiumHelper.track(title: "user_login", data: data)
        TealiumHelper.track(title: "user_alias", data: data)
    }
    
    private func gender() -> String {
        guard var genderString = genderSegmentedControl.titleForSegment(at: genderSegmentedControl.selectedSegmentIndex) else {
            return "prefernottosay"
        }
        if genderString.lowercased() == "n/a" {
            genderString = "notapplicable"
        }
        return genderString
    }


}
