//
//  MissionSettingsViewController.swift
//  DJISDKSwiftDemo
//
//  Created by Martin Ouellet on 2016-08-18.
//  Copyright © 2016 DJI. All rights reserved.
//
import UIKit
import DJISDK
import SwiftCSV
//let DEGREE_OF_THIRTY_METER = 0.0000899322 * 3


class MissionSettingsViewController:  DJIBaseViewController, DJIFlightControllerDelegate, DJIMissionManagerDelegate, NavigationWaypointConfigViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, NSURLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {

    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var missionPicker: UIPickerView!
    
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var tipsLabel: UILabel!
    
    var progressAlertView: UIAlertView? = nil
    var isEditEnable: Bool = false
    var waypointMission: DJIWaypointMission = DJIWaypointMission()
    var waypointConfigView: NavigationWaypointConfigView = NavigationWaypointConfigView()
    var waypointMissionConfigView: NavigationWaypointMissionConfigView? = nil
    var waypointList: [AnyObject]=[]
    var waypointAnnotations: [AnyObject]=[]
    var aircraftLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var missionManager:DJIMissionManager = DJIMissionManager.sharedInstance()!
    
    var downloadTask: NSURLSessionDownloadTask!
    var backgroundSession: NSURLSession!
    var filesArray = ["FirstMission", "GDIR_PlanVolChampCarrier1"]
    var indexSelected = 0
    var currentState: DJIFlightControllerCurrentState? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.waypointList = [AnyObject]()
        self.waypointAnnotations = [AnyObject]()
        self.isEditEnable = false
        self.waypointConfigView.alpha = 0
        self.waypointConfigView.delegate = self
        self.waypointConfigView.okButton.addTarget(self, action: #selector(NavigationWaypointViewController.onWaypointConfigOKButtonClicked(_:)), forControlEvents: .TouchUpInside)
        self.view!.addSubview(self.waypointConfigView)
        self.waypointMissionConfigView = NavigationWaypointMissionConfigView()
        self.waypointMissionConfigView!.alpha = 0
        self.waypointMissionConfigView!.okButton.addTarget(self, action: #selector(NavigationWaypointViewController.onMissionConfigOKButtonClicked(_:)), forControlEvents: .TouchUpInside)
        self.view!.addSubview(self.waypointMissionConfigView!)
        self.tipsLabel.layer.cornerRadius = 5.0
        self.tipsLabel.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("backgroundSession")
        backgroundSession = NSURLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        //progressView.setProgress(0.0, animated: false)
        self.missionPicker.dataSource = self
        self.missionPicker.delegate = self
        //self.tipsLabel.backgroundColor = UIColor(white: 1, alpha: 0.5)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSpeedSliderTouchDown(sender: UISlider) {
        self.tipsLabel.text = String(format: "%0.1fm/s", sender.value)
    }
    
    @IBAction func onSpeedSliderTouchUp(sender: UISlider) {
        DJIWaypointMission.setAutoFlightSpeed(sender.value, withCompletion: {[weak self] (error: NSError?) -> Void in
            self?.showAlertResult("Set auto flight speed(\(sender.value)m/s):\(error?.description)")
            })
    }
    
    @IBAction func onSpeedSliderValueChanged(sender: UISlider) {
        self.tipsLabel.text = String(format: "%0.1fm/s", sender.value)
    }

    
    @IBAction func downloadButtonClicked(sender: AnyObject) {
        self.missionPicker.hidden = false
        self.downloadButton.enabled = false
    }
    
    @IBAction func uploadButtonClicked(sender: AnyObject) {
        if CLLocationCoordinate2DIsValid(self.aircraftLocation) {
            self.updateMission()
            
            self.missionManager.prepareMission(self.waypointMission, withProgress:
                {[weak self] (progress: Float) -> Void in
                    
                    let message: String = "Mission Uploading:\(Int(100 * progress))%"
                    if self?.progressAlertView == nil {
                        self?.progressAlertView = UIAlertView(title: nil, message: message, delegate: nil, cancelButtonTitle:nil)
                        self?.progressAlertView!.show()
                    }
                    else {
                        self?.progressAlertView!.message = message
                    }
                    if progress == 1.0 {
                        self?.progressAlertView!.dismissWithClickedButtonIndex(0, animated: true)
                        self?.progressAlertView = nil
                    }
                }, withCompletion:{[weak self] (error: NSError?) -> Void in
                    
                    if self?.progressAlertView != nil  {
                        self?.progressAlertView!.dismissWithClickedButtonIndex(0, animated: true)
                        self?.progressAlertView = nil
                    }
                    if (error != nil) {
                        self?.showAlertResult("Upload Mission Result:\(error!.description)")
                    }
                })
        }
        else {
            self.showAlertResult("Current Drone Location Invalid")
        }

    }

    
    @IBAction func waypointConfigButtonClicked(sender: AnyObject) {
        UIView.animateWithDuration(0.25, animations: {() -> Void in
            self.waypointConfigView.alpha = 0
        })
    }
   
    
    @IBAction func onWaypointConfigButtonClicked(sender: AnyObject) {
        self.waypointConfigView.center = self.view.center
        self.waypointConfigView.waypointList = self.waypointList
        UIView.animateWithDuration(0.25, animations: {() -> Void in
            self.waypointConfigView.alpha = 1
        })
    }
    

    
    @IBAction func startButtonClicked(sender: AnyObject) {
        self.missionManager.startMissionExecutionWithCompletion({[weak self] (error: NSError?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Start Mission:\(error!.description)")
            }
            })
    }
    
    @IBAction func stopButtonClicked(sender: AnyObject) {
        self.missionManager.stopMissionExecutionWithCompletion({[weak self] (error: NSError?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Stop Mission:\(error!.description)")
            }
            })
    }
    
    
    @IBAction func pauseButtonClicked(sender: AnyObject) {
        self.missionManager.pauseMissionExecutionWithCompletion({[weak self] (error: NSError?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Pause Mission:\(error!.description)")
            }
            })
    }
    
    @IBAction func resumeButtonClicked(sender: AnyObject) {
        self.missionManager.resumeMissionExecutionWithCompletion({[weak self] (error: NSError?) -> Void in
            if (error != nil ) {
                self?.showAlertResult("Resume Mission:\(error!.description)")
            }
            })
    }
    
    
    func updateMission() {
        self.waypointMission.maxFlightSpeed = CFloat(self.waypointMissionConfigView!.maxFlightSpeed.text!)!
        self.waypointMission.autoFlightSpeed = CFloat(self.waypointMissionConfigView!.autoFlightSpeed.text!)!
        self.waypointMission.finishedAction = DJIWaypointMissionFinishedAction(rawValue: UInt8(self.waypointMissionConfigView!.finishedAction.selectedSegmentIndex))!
        self.waypointMission.headingMode = DJIWaypointMissionHeadingMode(rawValue: UInt(self.waypointMissionConfigView!.headingMode.selectedSegmentIndex))!
        self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode(rawValue: UInt(self.waypointMissionConfigView!.airlineMode.selectedSegmentIndex))!
        self.waypointMission.removeAllWaypoints()
        
        let point = self.waypointList.first;
        if (point != nil){
            self.waypointList.append(point!)
        }
        self.waypointMission.addWaypoints(self.waypointList)
        if self.waypointMission.flightPathMode == DJIWaypointMissionFlightPathMode.Curved {
            self.calcCornerRadius()
        }
    }

    func calcCornerRadius() {
        for i :Int32 in 0 ..< Int32(self.waypointMission.waypointCount) {
            let wp: DJIWaypoint = self.waypointMission.getWaypointAtIndex(i)!
            var prevWaypoint: DJIWaypoint? = nil
            var nextWaypoint: DJIWaypoint? = nil
            let prev: Int32 = i - 1
            let next: Int32 = i + 1
            if prev >= 0 {
                prevWaypoint = self.waypointMission.getWaypointAtIndex(prev)
            }
            if next < self.waypointMission.waypointCount {
                nextWaypoint = self.waypointMission.getWaypointAtIndex(next)
            }
            wp.cornerRadiusInMeters = Float(self.getCornerRadius(prevWaypoint!, middleWaypoint: wp, nextWaypoint: nextWaypoint!))
        }
    }
    
    func createWaypointMission() {
        let height: Float = 30.0
        self.waypointMission.removeAllWaypoints()
        self.waypointMission.maxFlightSpeed = 6.0
        self.waypointMission.autoFlightSpeed = 4.0
        self.waypointMission.finishedAction = DJIWaypointMissionFinishedAction.GoHome
        self.waypointMission.headingMode = DJIWaypointMissionHeadingMode.Auto
        self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.Normal
        //DJIWaypointMissionAirLineCurve
        var point1: CLLocationCoordinate2D
        var point2: CLLocationCoordinate2D
        var point3: CLLocationCoordinate2D
        var point4: CLLocationCoordinate2D
        point1 = CLLocationCoordinate2DMake(self.aircraftLocation.latitude + DEGREE_OF_THIRTY_METER, self.aircraftLocation.longitude)
        point2 = CLLocationCoordinate2DMake(self.aircraftLocation.latitude, self.aircraftLocation.longitude + DEGREE_OF_THIRTY_METER)
        point3 = CLLocationCoordinate2DMake(self.aircraftLocation.latitude - DEGREE_OF_THIRTY_METER, self.aircraftLocation.longitude)
        point4 = CLLocationCoordinate2DMake(self.aircraftLocation.latitude, self.aircraftLocation.longitude - DEGREE_OF_THIRTY_METER)
        let wp1: DJIWaypoint = DJIWaypoint(coordinate: point1)
        wp1.altitude = height
        let action1: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
        let action2: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateAircraft, param: -180)
        let action3: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
        let action4: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateAircraft, param: -90)
        let action5: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
        let action6: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateAircraft, param: 0)
        let action7: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
        let action8: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateAircraft, param: 90)
        let action9: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
        let action10: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateAircraft, param: 180)
        let action11: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateGimbalPitch, param: -45)
        wp1.addAction(action1)
        wp1.addAction(action2)
        wp1.addAction(action3)
        wp1.addAction(action4)
        wp1.addAction(action5)
        wp1.addAction(action6)
        wp1.addAction(action7)
        wp1.addAction(action8)
        wp1.addAction(action9)
        wp1.addAction(action10)
        wp1.addAction(action11)
        let wp2: DJIWaypoint = DJIWaypoint(coordinate: point2)
        wp2.altitude = height
        let action12: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.RotateGimbalPitch, param: 29)
        wp2.addAction(action12)
        let wp3: DJIWaypoint = DJIWaypoint(coordinate: point3)
        wp3.altitude = height
        let action14: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.StartRecord, param: 0)
        wp3.addAction(action14)
        let wp4: DJIWaypoint = DJIWaypoint(coordinate: point4)
        wp4.altitude = height
        let action15: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.StopRecord, param: 0)
        wp4.addAction(action15)
        self.waypointMission.addWaypoint(wp1)
        self.waypointMission.addWaypoint(wp2)
        self.waypointMission.addWaypoint(wp3)
        self.waypointMission.addWaypoint(wp4)
        self.waypointMission.addWaypoint(wp1)
        self.waypointMission.addWaypoint(wp2)
        self.waypointMission.addWaypoint(wp3)
        self.waypointMission.addWaypoint(wp4)
        if self.waypointMission.flightPathMode == DJIWaypointMissionFlightPathMode.Curved {
            self.calcCornerRadius()
        }
    }
    
    func getCornerRadius(pointA: DJIWaypoint?, middleWaypoint pointB: DJIWaypoint?, nextWaypoint pointC: DJIWaypoint?) -> CGFloat {
        if pointA == nil || pointB == nil || pointC == nil {
            return 2.0
        }
        let loc1: CLLocation = CLLocation(latitude: pointA!.coordinate.latitude, longitude: pointA!.coordinate.longitude)
        let loc2: CLLocation = CLLocation(latitude: pointB!.coordinate.latitude, longitude: pointB!.coordinate.longitude)
        let loc3: CLLocation = CLLocation(latitude: pointC!.coordinate.latitude, longitude: pointC!.coordinate.longitude)
        let d1: CLLocationDistance = loc2.distanceFromLocation(loc1)
        let d2: CLLocationDistance = loc2.distanceFromLocation(loc3)
        var dmin: CLLocationDistance = min(d1, d2)
        if dmin < 1.0 {
            dmin = 1.0
        }
        else {
            dmin = 1.0 + (dmin - 1.0) * 0.2
            dmin = min(dmin, 10.0)
        }
        return CGFloat(dmin)
    }

    
    func onWaypointConfigOKButtonClicked(sender: AnyObject) {
        UIView.animateWithDuration(0.25, animations: {() -> Void in
            self.waypointConfigView.alpha = 0
        })
    }
    
    func onMissionConfigOKButtonClicked(sender: AnyObject) {
        UIView.animateWithDuration(0.25, animations: {() -> Void in
            self.waypointMissionConfigView!.alpha = 0
        })
    }
    
    func configViewDidDeleteWaypointAtIndex(index: Int) {
        if index >= 0 && index < self.waypointAnnotations.count {
            let wpAnno: DJIWaypointAnnotation = self.waypointAnnotations[index] as! DJIWaypointAnnotation
            self.waypointAnnotations.removeAtIndex(index)
            NavigationWaypointViewController().mapView.removeAnnotation(wpAnno)
            for i in 0 ..< self.waypointAnnotations.count {
                let wpAnno: DJIWaypointAnnotation = self.waypointAnnotations[i] as! DJIWaypointAnnotation
                wpAnno.text = "\(i + 1)"
                let annoView: DJIWaypointAnnotationView = NavigationWaypointViewController().mapView.viewForAnnotation(wpAnno) as! DJIWaypointAnnotationView
                annoView.titleLabel!.text = wpAnno.text!
            }
        }
    }
    
    func configViewDidDeleteAllWaypoints() {
        for i in 0 ..< self.waypointAnnotations.count {
            let wpAnno: DJIWaypointAnnotation = self.waypointAnnotations[i] as! DJIWaypointAnnotation
            NavigationWaypointViewController().mapView.removeAnnotation(wpAnno)
        }
        self.waypointAnnotations.removeAll()
        self.waypointList.removeAll()
    }
    
    func onMapViewTap(tapGestureRecognizer: UIGestureRecognizer) {
        if self.isEditEnable {
            let point: CGPoint = tapGestureRecognizer.locationInView(NavigationWaypointViewController().mapView)
            let touchedCoordinate: CLLocationCoordinate2D = NavigationWaypointViewController().mapView.convertPoint(point, toCoordinateFromView: NavigationWaypointViewController().mapView)
            let waypoint: DJIWaypoint = DJIWaypoint(coordinate: touchedCoordinate)
            self.waypointList.append(waypoint)
            let wpAnnotation: DJIWaypointAnnotation = DJIWaypointAnnotation()
            wpAnnotation.coordinate = touchedCoordinate
            wpAnnotation.text = "\(Int(self.waypointList.count))"
            NavigationWaypointViewController().mapView.addAnnotation(wpAnnotation)
            self.waypointAnnotations.append(wpAnnotation)
        }
    }
    
    func missionManager(manager: DJIMissionManager, missionProgressStatus missionProgress: DJIMissionProgressStatus) {
        if (missionProgress is DJIWaypointMissionStatus) {
            //            var wpmissionStatus: DJIWaypointMissionStatus = missionProgress as! DJIWaypointMissionStatus
        }
    }
    
    func flightController(fc: DJIFlightController, didUpdateSystemState state: DJIFlightControllerCurrentState) {
        self.currentState = state
        self.aircraftLocation = state.aircraftLocation
        if CLLocationCoordinate2DIsValid(state.aircraftLocation) {
            let heading: Double = state.attitude.yaw*M_PI/180.0
            NavigationWaypointViewController().djiMapView!.updateAircraftLocation(state.aircraftLocation, withHeading: heading)
            
        }
        if CLLocationCoordinate2DIsValid(state.homeLocation) {
            NavigationWaypointViewController().djiMapView!.updateHomeLocation(state.homeLocation)
        }
    }

    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return filesArray.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        print("mission selected =  " + filesArray[row])
        NavigationWaypointViewController().setNavTitle(filesArray[row])
        //self.title = filesArray[row]
        self.indexSelected = row
        self.missionPicker.hidden = true
        self.downloadButton.enabled = true
        //let url = NSURL(string: "https://www.dropbox.com/s/19sepkw02kiizrm/FirstMission.waypoints?dl=1")!
        //let url = NSURL(string: "https://dl.dropboxusercontent.com/u/23634529/test3.csv?dl=1")!
        //good one
        //
        
        var dropboxURL: String = ""
        if row == 0 {
            dropboxURL = "https://www.dropbox.com/s/19sepkw02kiizrm/FirstMission.waypoints?dl=1"
        }
        if row == 1 {
            dropboxURL = "https://www.dropbox.com/s/aphw8opb99erddv/GDIR_PlanVolChampCarrier1.waypoints?dl=1"
        }
        let url = NSURL(string: dropboxURL)!
        downloadTask = backgroundSession.downloadTaskWithURL(url)
        downloadTask.resume()
        
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) ->String?{
        return filesArray[row]
    }
    
    func URLSession(session: NSURLSession,
                    downloadTask: NSURLSessionDownloadTask,
                    didFinishDownloadingToURL location: NSURL){
        
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = NSFileManager()
        let uuidFilename = "gdir_" + NSUUID().UUIDString + ".csv"
        print("unique filename=" + uuidFilename)
        let destinationURLForFile = NSURL(fileURLWithPath: documentDirectoryPath.stringByAppendingString("/" + uuidFilename))
        
        if fileManager.fileExistsAtPath(destinationURLForFile.path!){
            showFileWithPath(destinationURLForFile.path!)
        }
        else{
            do {
                try fileManager.moveItemAtURL(location, toURL: destinationURLForFile)
                // show file
                showFileWithPath(destinationURLForFile.path!)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }
    // 2
    func URLSession(session: NSURLSession,
                    downloadTask: NSURLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                                 totalBytesWritten: Int64,
                                 totalBytesExpectedToWrite: Int64){
        //progressView.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
    }
    
    
    func URLSession(session: NSURLSession,
                    task: NSURLSessionTask,
                    didCompleteWithError error: NSError?){
        downloadTask = nil
        //progressView.setProgress(0.0, animated: true)
        if (error != nil) {
            print(error?.description)
        }else{
            print("The task finished transferring data successfully")
        }
    }
    
    func showFileWithPath(path: String){
        let height: Float = 30.0
        self.waypointMission.removeAllWaypoints()
        self.waypointMission.maxFlightSpeed = 6.0
        self.waypointMission.autoFlightSpeed = 4.0
        self.waypointMission.finishedAction = DJIWaypointMissionFinishedAction.GoHome
        self.waypointMission.headingMode = DJIWaypointMissionHeadingMode.Auto
        self.waypointMission.flightPathMode = DJIWaypointMissionFlightPathMode.Normal
        self.waypointAnnotations.removeAll()
        self.waypointList.removeAll()
        //DJIWaypointMissionAirLineCurve
        
        let isFileFound:Bool? = NSFileManager.defaultManager().fileExistsAtPath(path)
        if isFileFound == true{
            //let viewer = UIDocumentInteractionController(URL: NSURL(fileURLWithPath: path))
            //viewer.delegate = self
            //viewer.presentPreviewAnimated(true)
            do {
                let csv = try CSV(name: path, delimiter: "\t", encoding: NSUTF8StringEncoding, loadColumns: false)
                
                //var point1: CLLocationCoordinate2D
                //var wp1: DJIWaypoint
                let action1: DJIWaypointAction = DJIWaypointAction(actionType: DJIWaypointActionType.ShootPhoto, param: 0)
                
                csv.enumerateAsArray { array in
                    //array[8], array[9], array[10]
                    if ((array[8] as NSString).doubleValue > 0 ){
                        let point1 = CLLocationCoordinate2DMake((array[8] as NSString).doubleValue + DEGREE_OF_THIRTY_METER, (array[9] as NSString).doubleValue)
                        let wp1 = DJIWaypoint(coordinate: point1)
                        self.waypointList.append(wp1)
                        wp1.altitude = (array[10] as NSString).floatValue
                        wp1.addAction(action1)
                        self.waypointMission.addWaypoint(wp1)
                        if self.waypointMission.flightPathMode == DJIWaypointMissionFlightPathMode.Curved {
                            self.calcCornerRadius()
                        }
                        let wpAnnotation: DJIWaypointAnnotation = DJIWaypointAnnotation()
                        wpAnnotation.coordinate = point1
                        wpAnnotation.text = "\(Int(self.waypointList.count))"
                        NavigationWaypointViewController().mapView.addAnnotation(wpAnnotation)
                        //self.mapView.addAnnotation(wpAnnotation)
                        self.waypointAnnotations.append(wpAnnotation)
                    }
                }
                //print(tsv.columns)
                //print(tsv.rows)
                NavigationWaypointViewController().djiMapView?.zoomToFitMapAnnotations(self.waypointList)
                //self.djiMapView?.zoomToFitMapAnnotations(self.waypointList)
            } catch {
                // Error handling
            }
        }
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
