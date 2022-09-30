//
//  RouteViewController.swift
//  MyNavi
//
//  Created by Wenfeng Ge on 2020-10-25.
//

import UIKit
import MapKit

class RouteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var textFrom: UITextField!
    @IBOutlet weak var textTo: UITextField!
    @IBOutlet weak var tableRoutes: UITableView!
    
    var delegate: RouteViewDelegate?  // delegate to pass data
    
    var index: Int = 0
    var fromAddr: String = ""
    var toAddr: String = ""
    var currentAddr:String = ""
    var routes: [MKRoute] = []
    var routeStartPlace: CLPlacemark?
    var routeEndPlace: CLPlacemark?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("in routeview currentAddr:" + self.currentAddr)
        textFrom.text = self.fromAddr
        textTo.text = self.toAddr
        if self.routes.count > 0 {
            tableRoutes.reloadData()
            let indexPath = IndexPath(row: index, section: 0)
            tableRoutes.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.none)
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell()

        let index = indexPath.row
        let route = routes[index]
        let name = "via " + route.name
        let dist = String(format: "%.2f", route.distance/1000.0) + "Km"
        let time = route.expectedTravelTime.timeString

        cell.textLabel?.text = name + ": " + dist + ", " + time
       
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.index = indexPath.row
        self.delegate?.routeViewDidFinish(sender: self, index: self.index, fromAddr: self.fromAddr, toAddr: self.toAddr, routes: self.routes, start: self.routeStartPlace, end: self.routeEndPlace)
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func clickRouteButton(_ sender: Any)
    {
        toAddr = textTo.text ?? ""
        fromAddr = textFrom.text ?? ""
        
        if toAddr.isEmpty {
            let msg = "Please enter the destination address."
            let alertController = UIAlertController(title: "Empty Destination", message: msg, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        }else{
            print("from:" + fromAddr)
            print("to:" + toAddr)
            var realFromAddr: String = fromAddr
            if realFromAddr.isEmpty {
                realFromAddr = self.currentAddr
            }
            print("from2:" + realFromAddr)
            print("to2:" + toAddr)

            forwardGeocoding(address: realFromAddr, completion: { (placemark) in
                if let placeFrom = placemark {
                    self.routeStartPlace = placeFrom
                    if let locationFrom = placeFrom.location {
                        self.forwardGeocoding(address: self.toAddr, completion: { (placemark) in
                            if let placeTo = placemark {
                                self.routeEndPlace = placeTo
                                if let locationTo = placeTo.location {
                                    self.route(from:locationFrom, to:locationTo)
                                }else{// not found destination location, show alert
                                    let msg = "Destination location is not found."
                                    let alertController = UIAlertController(title: "Destination Not Found", message: msg, preferredStyle: .alert)
                                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                    alertController.addAction(cancelAction)
                                    self.present(alertController, animated: true)
                                    
                                }
                            }else{ // not found destination placemark, show alert
                                let msg = "Destination placemark is not found."
                                let alertController = UIAlertController(title: "Destination Not Found", message: msg, preferredStyle: .alert)
                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                alertController.addAction(cancelAction)
                                self.present(alertController, animated: true)

                            } })
                    }else {// not found the source location, show alert
                        let msg = "Source location is not found."
                        let alertController = UIAlertController(title: "Source Not Found", message: msg, preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(cancelAction)
                        self.present(alertController, animated: true)
                        
                    }
                }
                else { // not found the source placemark, show alert
                    let msg = "Source placemark is not found."
                    let alertController = UIAlertController(title: "Source Not Found", message: msg, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true)

                } })
        }
        
        
    
    }
    
    func forwardGeocoding(address:String, completion: @escaping ((CLPlacemark?) -> Void))
    {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if let error = error {
                completion(nil)
                print(error) // display alert later
            }
            else { // found locations, then perform the next task using closure
                completion(placemarks?[0]) // execute closure
            }
        })
    }

    func route(from: CLLocation, to: CLLocation) {
        // request directions
        let request = MKDirections.Request()
        let fromPlacemark = MKPlacemark(coordinate: from.coordinate)
        let toPlacemark = MKPlacemark(coordinate: to.coordinate)
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        // calculate directions
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: { (response, error) in
            if let error = error {
                // show alert
                print(error)
                return
            }
            if let routes = response?.routes {
                for route in routes
                {
                    print("Name: " + route.name)
                    print("Distance: \(route.distance)")
                    print("Expected Travel Time: \(route.expectedTravelTime)")
                    
                }
                self.routes = routes
                self.tableRoutes.reloadData()
            }
        })
    }
    
    
    

}

protocol RouteViewDelegate : AnyObject
{
    //abstract func
    func routeViewDidFinish(sender: RouteViewController, index: Int, fromAddr: String, toAddr:String, routes: [MKRoute],  start: CLPlacemark?, end: CLPlacemark?)
    
}

extension TimeInterval {
    var timeString: String {
        let total = Int(self)
        let hh: Int = total/3600
        let mm: Int = (total%3600)/60
        let ss: Int = total%60
        return String(format: "%0.2d:%0.2d:%0.2d", hh, mm, ss)
    }
}
