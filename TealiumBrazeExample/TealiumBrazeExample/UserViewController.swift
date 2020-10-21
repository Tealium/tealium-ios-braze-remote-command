//
//  UserViewController.swift
//  TealiumBrazeExample
//
//  Created by Jonathan Wong on 5/29/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit
import TealiumBraze

class UserViewController: UIViewController {

    let dobDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        return dateFormatter
    }()
    
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
        
        TealiumHelper.trackEvent(title: "user_alias", data: nil)
    }
    
    @IBAction func onSend( _ sender: UIButton) {
        var data = [String: Any]()
        data["customer_first_name"] = firstNameTextField.text
        data["customer_last_name"] = lastNameTextField.text
        data["customer_email"] = emailTextField.text
        data["customer_gender"] = gender()
        data["customer_language"] = "en"
        data["customer_home_city"] = homeCityTextField.text
        
        if let birthday = dobDateFormatter.date(from: birthdayTextField.text!) {
            let isoBirthday = DateConverter.shared.iso8601DateFormatter.string(from: birthday)
            data["customer_dob"] = isoBirthday
        }
        data["customer_id"] = usernameTextField.text
        data["customer_alias"] = userAliasTextField.text
        data["customer_alias_label"] = userLabelTextField.text
        
        TealiumHelper.trackEvent(title: "user_attribute", data: data)
        TealiumHelper.trackEvent(title: "user_login", data: data)
        TealiumHelper.trackEvent(title: "user_alias", data: data)
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
