//
//  ViewController.swift
//  VStore
//
//  Created by Charles Xu on 2/6/21.
//

import UIKit
import Alamofire
import SwiftyJSON

class RegisterViewController: UIViewController {
    var email: String! = ""
    var salutation: String! = ""
    var fname: String! = ""
    var lname: String! = ""
    var phone: String! = ""
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var salutationField: UITextField!
    
    @IBOutlet weak var fnameField: UITextField!
    
    @IBOutlet weak var lnameField: UITextField!
    
    @IBOutlet weak var phoneField: UITextField!
    
    @IBOutlet weak var msgField: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func register(_ sender: UIButton) {
        email = emailField.text
        salutation = salutationField.text
        fname = fnameField.text
        lname = lnameField.text
        phone = emailField.text
        
        let parameters: [String: Any] = [
            "email": email!,
            "salutation": salutation!,
            "first_name": fname!,
            "last_name": lname!,
            "phone_number": phone!
        ]

        
        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/createConsumer", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData {response in
            if let _ = response.data {
                do{
                    
                    
                    let convertedString = String(data: response.data!, encoding: String.Encoding.utf8)
                    print(convertedString!)
                    self.msgField.isHidden = false
                    self.msgField.text = "You password is: \(convertedString!), please store it in a secured place"
                }
                catch{
                    print("JSON Error")
                }
            }
        }
        
    }
    
    
}
