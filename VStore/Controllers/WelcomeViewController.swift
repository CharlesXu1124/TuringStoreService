//
//  ViewController.swift
//  VStore
//
//  Created by Charles Xu on 2/6/21.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func register(_ sender: UIButton) {
        performSegue(withIdentifier: "register", sender: self)
        
    }
    
    @IBAction func login(_ sender: UIButton) {
        performSegue(withIdentifier: "login", sender: self)
    }
    
}
