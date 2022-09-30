//
//  MapViewController.swift
//  MyNavi
//
//  Created by Wenfeng Ge on 2020-10-25.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate, RouteViewDelegate {

    @IBOutlet weak var myMap: MKMapView!
    
    var index: Int = 0
    var fromAddr: String = ""
    var toAddr: String = ""
    var currentAddr:String = ""
    var routes: [MKRoute] = []
    var routeStartPlace: CLPlacemark?
    var routeEndPlace: CLPlacemark?
    var startPin = MKPointAnnotation()
    var endPin = MKPointAnnotation()
    var isStartPinned: Bool = false
    var isEndPinned: Bool = false
    var currentPlace: CLLocation?
    
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        myMap.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "segueRoute" {
            if let vc = segue.destination as? RouteViewController{
                vc.delegate = self          // to receive data from dst vc
                vc.currentAddr = self.currentAddr
                vc.fromAddr = self.fromAddr
                vc.toAddr = self.toAddr
                vc.index = self.index
                vc.routes = self.routes
                vc.routeStartPlace = self.routeStartPlace
                vc.routeEndPlace = self.routeEndPlace
            }
        }

    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let coord = locations.first?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center:center, span:span)
            myMap.setRegion(region, animated: true)
        }
        
        if let currentLocation = locations.first {
            self.currentPlace = currentLocation
            reverseGeocoding(location: currentLocation, completion: { (placemark) in
                if let place = placemark {
                    let nameString: String = place.name ?? ""
                    let streetNum: String = place.subThoroughfare ?? ""
                    let streetAddr: String = place.thoroughfare ?? ""
                    let city: String = place.locality ?? ""
                    let province: String = place.administrativeArea ?? ""
                    let country: String = place.country ?? ""
                    let postal: String = place.postalCode ?? ""
                    
                    self.currentAddr = nameString + "," + streetNum + "," + streetAddr + "," + city + "," + province + "," + country + "," + postal
                    print(self.currentAddr)  //to test
                }
                
            })
        }
    }

    func reverseGeocoding(location: CLLocation, completion: @escaping((CLPlacemark?) -> Void))
    {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if let error = error
            {
                print(error.localizedDescription)
                completion(nil) // passing null placemark
            }
            else
            {   // pass the first placemark to closure
                completion(placemarks?[0])
            }
        })
    }
    
    func routeViewDidFinish(sender: RouteViewController, index: Int, fromAddr: String, toAddr:String, routes:[MKRoute], start: CLPlacemark?, end: CLPlacemark?)
    {
        self.index = index
        self.fromAddr = fromAddr
        self.toAddr = toAddr
        self.routes = routes
        self.routeStartPlace = start
        self.routeEndPlace = end
        
        print("back in map: index:" + String(self.index))
        print("back in map: route name:" + String(self.routes[self.index].name))
        print("back in map: fromtxt:" + self.fromAddr)
        print("back in map: totxt:" + self.toAddr)
        
        if let routeEnd = end {
            print("back in map: routeEndPlace: " + (routeEnd.name ?? "endname null"))
            if let endLocation = routeEnd.location{
                self.endPin.coordinate = endLocation.coordinate
            }
            self.endPin.title = routeEnd.name
            print("isEndPinned first: " + String(isEndPinned))
            
            if !isEndPinned {
                myMap.addAnnotation(endPin)
                isEndPinned = true
            }
            print("isEndPinned second: " + String(isEndPinned))
            print("test end: ")
            
        }
        
        if let routeStart = start {
            print("back in map: routeStartPlace: " + (routeStart.name ?? "startname null"))
            if let startLocation = routeStart.location{
                self.startPin.coordinate = startLocation.coordinate
                
            }
            self.startPin.title = routeStart.name
            print("isStartPinned: first" + String(isStartPinned))
           
            if let current = self.currentPlace {
                //if we have current location then we need to compare it with startpoint to decide if show annotation
                //we set an error allowed, after tests, it seems 100m is acceptable
                let error: Int = 100
                if isStartPinned && (Int(current.distance(from: CLLocation(latitude: self.startPin.coordinate.latitude, longitude: self.startPin.coordinate.longitude))) < error) {
                    //if distance < error, consider them are equal location
                    myMap.removeAnnotation(startPin)
                    isStartPinned = false
                } else {
                    if (!isStartPinned) && (Int(current.distance(from: CLLocation(latitude: self.startPin.coordinate.latitude, longitude: self.startPin.coordinate.longitude)))>=error){
                        myMap.addAnnotation(startPin)
                        isStartPinned = true
                        print(Int(current.distance(from: CLLocation(latitude: self.startPin.coordinate.latitude, longitude: self.startPin.coordinate.longitude))))
                    }
                }
                print("isStartPinned: second" + String(isStartPinned))
                print("test start: ")
            }else{
                myMap.addAnnotation(startPin)
                isStartPinned = true
            }
        }
        
        let route:MKRoute = routes[index]
        let overlays = myMap.overlays
        myMap.removeOverlays(overlays)
        myMap.addOverlay(route.polyline, level:MKOverlayLevel.aboveRoads)
        myMap.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top:16, left:16, bottom:16, right:16), animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let render = MKPolylineRenderer(polyline: polyline)
            render.strokeColor = UIColor.blue
            render.lineWidth = 2
            return render
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    @IBAction func changeMapMode(_ sender: UIBarButtonItem){
        if sender.title == "Satellite" {
            myMap.mapType = .satellite
            sender.title = "Hybrid"
        }else if sender.title == "Hybrid" {
            myMap.mapType = .hybrid
            sender.title = "Standard"
        }else{
            myMap.mapType = .standard
            sender.title = "Satellite"
        }
    }
    
}

