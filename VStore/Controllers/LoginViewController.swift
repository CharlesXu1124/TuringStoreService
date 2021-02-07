//
//  ViewController.swift
//  VStore
//
//  Created by Charles Xu on 2/6/21.
//

import UIKit
import Alamofire
import SwiftyJSON

class LoginViewController: UIViewController {
    var email:String! = ""
    var password:String! = ""
    var authenticateMSG:String! = ""
    var userID:String! = ""
    var addressing:String! = ""
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var warningField: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func login(_ sender: UIButton) {
        email = emailField.text!
        password = passwordField.text!
        
        let parameters: [String: Any] = [
            "email": email!,
            "password": password!
        ]

        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/authenticateUser", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData {response in
            if let json = response.data {
                do{
                    let authenticateData = try JSON(data: json)
                    self.authenticateMSG = "\(authenticateData[0])"
                    
                    if self.authenticateMSG == "pass" {
                        self.userID = "\(authenticateData[1])"
                        self.addressing = "\(authenticateData[2])"
                        self.performSegue(withIdentifier: "loginToUser", sender: self)
                    } else {
                        self.warningField.isHidden = false
                    }
                    
                }
                catch{
                    print("JSON Error")
                    self.warningField.isHidden = false
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let uv = segue.destination as? UserViewController {
            uv.userID = self.userID
            uv.addressing = self.addressing
        }
    }
    
}
