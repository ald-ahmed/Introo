//
//  LocationHandler.swift
//  Intro
//
//  Created by Ahmed Al Dulaimy on 6/9/18.
//  Copyright © 2018 Intro. All rights reserved.
//


import MapKit
import CoreLocation

class LocationController: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    public func startLocationTracking() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        let center = location.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        
        print (center)
    }
    
    
    
}
