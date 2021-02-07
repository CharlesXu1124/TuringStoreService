//
//  ViewController.swift
//  VStore
//
//  Created by Charles Xu on 2/6/21.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON

class UserViewController: UIViewController, UIGestureRecognizerDelegate {
    var userID: String! = ""
    var addressing: String! = ""
    
    var latitude: Double!
    var longitude: Double!
    var coordinates: [CLLocationCoordinate2D] = []
    
    @IBOutlet weak var welcomeField: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var locationField: UILabel!
    
    @IBOutlet weak var storeCreationField: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeField.text = "welcome back,  \(addressing!)!"
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func longTap(sender: UIGestureRecognizer){
        
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addToMap(location: locationOnMap)
            latitude = locationOnMap.latitude
            longitude = locationOnMap.longitude
            print("latitude: \(latitude), longitude: \(longitude)")
            performRequest(withLat: latitude, withLong: longitude)
        }
    }
    
    func addToMap(location: CLLocationCoordinate2D){
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "Turing Store"
            //annotation.subtitle = "Some Subtitle"
            self.mapView.addAnnotation(annotation)
    }
    
    // helper function for making request to radar.io reverse geo api
    func performRequest(withLat latitude: Double, withLong longitude: Double){
        let headers: HTTPHeaders = [
            "Authorization": "prj_live_pk_3d1dff29f680dff29dadf58c7d56f05fc4506403",
        ]
        let url = "https://api.radar.io/v1/geocode/reverse?coordinates=\(latitude),\(longitude)"
        
        AF.request(url, method: .get, headers: headers ).validate().responseData { response in
            switch response.result {
            case .success(let value):
                //print(String(data: value, encoding: .utf8)!)
                if let json = response.data {
                    do{
                        let data = try JSON(data: json)
                        let locationJSON = data["addresses"][0]["formattedAddress"]
                        //print("location: \(location)")
                        self.locationField.text = "\(locationJSON)"
                        //self.location = self.locationField.text
                    }
                    catch{
                        print("JSON Error")
                    }

                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func searchStore(withRadius radius: Double) {
        print(radius)
        let parameters: [String: Any] = [
            "latitude": self.latitude!,
            "longitude": self.latitude!,
            "radius": radius,
            "numSites": 100
        ]

        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/getNearbyStores", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData {response in
            if let json = response.data {
                do{
                    let authenticateData = try JSON(data: json)
                    print(authenticateData)
                    // use swifty JSON to loop over entire array of stores
                    authenticateData.dictionaryValue.forEach({
                        // print($0.1)
                        let lat = "\($0.1[0])"
                        let lon = "\($0.1[1])"
                        let double_lat = NumberFormatter().number(from: lat)?.doubleValue
                        let double_lon = NumberFormatter().number(from: lon)?.doubleValue
                        print(double_lat)
                        print(double_lon)
                        self.loadPostOnMap(withLatitude: double_lat!, withLongitude: double_lon!)
                    })
                }
                catch{
                    print("JSON Error")
                    self.storeCreationField.text = "Search request failed!"
                    self.storeCreationField.isHidden = false
                }
            }
        }
    }
    
    func loadPostOnMap(withLatitude lat: Double, withLongitude lon: Double) {
        addToMap(location: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    
    
    @IBAction func searchStore(_ sender: UIButton) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Dear \(addressing!)", message: "Please Enter search radius", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping
            self.searchStore(withRadius: Double((textField?.text)!)!)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addStore(_ sender: UIButton) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Dear \(addressing!)", message: "Please Enter New Store Name", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping
            self.addStore(withName: (textField?.text)!)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func addStore(withName storeName: String) {
        print(storeName)
        let parameters: [String: Any] = [
            "siteName": storeName,
            "latitude": self.latitude!,
            "longitude": self.latitude!
        ]

        AF.request("http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/createStore", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData {response in
            if let json = response.data {
                do{
                    self.storeCreationField.text = "Store Added to Database"
                    self.storeCreationField.isHidden = false
                }
                catch{
                    print("JSON Error")
                    self.storeCreationField.text = "Store Failed to Add!"
                    self.storeCreationField.isHidden = false
                }
            }
        }
        
    }
    
    
    @IBAction func enterShop(_ sender: UIButton) {
        performSegue(withIdentifier: "toShop", sender: self)
    }
    
}
