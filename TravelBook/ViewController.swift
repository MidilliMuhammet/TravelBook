//
//  ViewController.swift
//  TravelBook
//
//  Created by Muhammet Midilli on 4.03.2021.
//

import UIKit
//to use map
import MapKit
//to use user location
import CoreLocation
//to save
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentLable: UILabel!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    
    
    //varibles
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    var selectedTitle = ""
    var selectedID : UUID?
    //pin variables
    var annotationTitle = ""
    var annotationSubtile = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    //delivery of location-related event
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //to delegate mapview
        mapView.delegate = self
        //to delegate location manager
        locationManager.delegate = self
        //to desired/request accurasy/correctness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //to request from user
        locationManager.requestWhenInUseAuthorization()
        //to update location
        locationManager.startUpdatingLocation()
        
        //enable to add pin when long press
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        //press time
        gestureRecognizer.minimumPressDuration = 1.5 //second
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //goes to other segue if press add button open empty details to add if press any row open details of row
        if selectedTitle != "" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedID!.uuidString
            //filter
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtile = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        //creat pin
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtile
                                        //adding coordinate information to pin
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameLabel.isHidden = false
                                        commentLable.isHidden = false
                                        nameLabel.text = annotationTitle
                                        commentLable.text = annotationSubtile
                                        nameText.isHidden = true
                                        commentText.isHidden = true
                                        saveButtonOutlet.isEnabled = false
                                        //map does not follow
                                        locationManager.stopUpdatingLocation()
                                        //map opens at center of pin
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
        } else {
            
        }
        //hide the keyboard when tap without keyboard
        let hidingGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(hidingGestureRecognizer)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    
    //for gestureRecognizer
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        //if user press longly
        if gestureRecognizer.state == .began {
            //touch point
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            //convert point to coordinate
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            //add to varibles
            chosenLatitude = touchCoordinates.latitude
            chosenLongitude = touchCoordinates.longitude
            //for pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            //adding pin
            self.mapView.addAnnotation(annotation)
        }
    }
    
    //search didupdatelocation, updated locations given as an array
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //zoom level
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            //centre of map
            let region = MKCoordinateRegion(center: location, span: span)
            //setting region
            mapView.setRegion(region, animated: true)
        }
    }
    
    //customize pin, search "viewforannotation"
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //do not show any pin on user location
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            //create to enable to add button in pin
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //after tap pin button, search callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            //closure
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlaceMark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        //alert function
        func alertFunc(title: String, message: String){
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(okButton)
            self.present(alert, animated: true, completion: nil)
        }
        //to delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        //save
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        if nameText.text == "" {
            alertFunc(title: "Missing Information", message: "Fill name field")
        }
        else if chosenLongitude == 0 && chosenLatitude == 0 {
            alertFunc(title: "Missing Information", message: "Add pin")
        } else {
            do {
                try context.save()
                print("success saving")
            } catch {
                print("failed saving")
            }
        }
        //go back to previus vc
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    

}

