//
//  WaypointSettingsViewController.swift
//  DJISDKSwiftDemo
//
//  Created by Martin Ouellet on 2016-08-18.
//  Copyright © 2016 DJI. All rights reserved.
//

import UIKit
import MapKit
import DJISDK

class WaypointSettingsViewController: UIViewController {

    @IBOutlet weak var addWaypointButton: UIButton!
    @IBOutlet weak var configButton: UIButton!
    
    var isEditEnable: Bool = false
    var tapGesture: UITapGestureRecognizer? = nil
    
    @IBAction func addWaypointClicked(sender: AnyObject) {
        
        self.isEditEnable = !self.isEditEnable
        if self.isEditEnable {
            self.tapGesture = UITapGestureRecognizer(target: NavigationWaypointViewController(), action: #selector(NavigationWaypointViewController.onMapViewTap(_:)))
            self.view!.addGestureRecognizer(self.tapGesture!)
            sender.setTitle("Finished", forState: .Normal)
        }
        else {
            sender.setTitle("Add Waypoint", forState: .Normal)
            if (self.tapGesture != nil) {
                self.view!.removeGestureRecognizer(self.tapGesture!)
                self.tapGesture = nil
            }
        }
    }
    
    func onMapViewTap(tapGestureRecognizer: UIGestureRecognizer) {
        if self.isEditEnable {
            let point: CGPoint = tapGestureRecognizer.locationInView(NavigationWaypointViewController().mapView)
            let touchedCoordinate: CLLocationCoordinate2D = NavigationWaypointViewController().mapView.convertPoint(point, toCoordinateFromView: NavigationWaypointViewController().mapView)
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: touchedCoordinate)
            NavigationWaypointViewController().waypointList.append(waypoint)
            let wpAnnotation: DJIWaypointAnnotation = DJIWaypointAnnotation()
            wpAnnotation.coordinate = touchedCoordinate
            wpAnnotation.text = "\(Int(NavigationWaypointViewController().waypointList.count))"
            NavigationWaypointViewController().mapView.addAnnotation(wpAnnotation)
            NavigationWaypointViewController().waypointAnnotations.append(wpAnnotation)
        }
    }

    
    @IBAction func configButtonClicked(sender: AnyObject) {
        //self.waypointConfigView.center = self.view.center
        //self.waypointConfigView.waypointList = self.waypointList
        //UIView.animateWithDuration(0.25, animations: {() -> Void in
        //    self.waypointConfigView.alpha = 1
        //})
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
