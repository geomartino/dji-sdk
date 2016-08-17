//
//  SequoiaCameraSettingsViewController.swift
//  DJISDKSwiftDemo
//
//  Created by Martin Ouellet on 2016-07-27.
//  Copyright © 2016 DJI. All rights reserved.
//

import UIKit

class SequoiaCameraSettingsViewController: DJIBaseViewController, NSXMLParserDelegate{
    
    @IBOutlet weak var BntTakeOne: UIButton!
    @IBOutlet weak var BntActiveFlight: UISwitch!
    @IBOutlet weak var BntUnits: UISegmentedControl!
    @IBOutlet weak var TxtUnitQuantity: UITextField!
    @IBOutlet weak var LblPictureMode: UILabel!
    @IBOutlet weak var BntStorageType: UISegmentedControl!
    
    
    @IBAction func BntStorageTypeToggle(sender: AnyObject) {
        let com = "config"
        var js = "{\"source\":\"sd\",\"type\":\"setmemory\"}"
        // source : interne ou sd
        if (BntStorageType.selectedSegmentIndex == 0){
            js = "{\"source\":\"interne\",\"type\":\"setmemory\"}";
        }
        execommSoap(com, mjson: js);
    }
    
    
    @IBAction func BntUnitsToggle(sender: AnyObject) {
        let com = "capture"
        let param = TxtUnitQuantity.text
        var js = "{\"type\":\"setmode\", mode:\"timelapse\"}"
        var js2 = "{\"type\":\"setmodeparam\", mode:\"timelapse\", param:\"" + param! + "\"}"
        // every meter or seconds
        if (BntStorageType.selectedSegmentIndex == 0){
            js = "{\"type\":\"setmode\", mode:\"gps\"}"
            js2 = "{\"type\":\"setmodeparam\", mode:\"gps\", param:\"" + param! + "\"}"
        }
        execommSoap(com, mjson: js);
        execommSoap(com, mjson: js2);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        var com = "capture"
        var js = "{\"type\":\"setmode\", mode:\"single\"}"
        execommSoap(com, mjson: js);

        com = "config"
        js = "{\"source\":\"interne\",\"type\":\"setmemory\"}"
        // source : interne ou sd
        execommSoap(com, mjson: js);
            
    }

    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func BntActiveFlightPress(sender: AnyObject) {
        if BntActiveFlight.on {
            //"The Switch is now On"
            BntUnits.enabled = true
            TxtUnitQuantity.enabled = true
            TxtUnitQuantity.userInteractionEnabled = true
            LblPictureMode.enabled = true
        } else {
            //"The Switch is now OFF"
            BntUnits.enabled = false
            TxtUnitQuantity.enabled = false
            TxtUnitQuantity.userInteractionEnabled = false
            LblPictureMode.enabled = false
        }
    }
    
    @IBAction func BntTakeOne(sender: UIButton) {
        var com = "";
        var js = "";
        
        if (BntTakeOne.titleLabel?.text == "Start Capture"){
            com = "capture";
            js = "{\"type\":\"capture\"}";
            
            if (BntActiveFlight.on){
                BntTakeOne.setTitle("Stop Capture", forState: UIControlState.Normal)
            }
            
        }
        else{
            com = "stop";
            js = "{\"capture\":\"stop\"}";
            BntTakeOne.setTitle("Start Capture", forState: UIControlState.Normal)
        }
        
        execommSoap(com, mjson: js);
    }
    
    //fonction pour intéroger le web service sur le Raspberry PI
    // comm : la commande a execute sur la sequoia et mjson : le json des parametres a utilises
    func execommSoap(comm: String, mjson: String){
        var soapMessage = "<?xml version='1.0' encoding='utf-8'?><soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:cgq='http://cgq.com/'><soapenv:Header/><soapenv:Body><cgq:execommandHTTP><commande>";
        
        soapMessage = soapMessage+comm+"</commande><param>"+mjson+"</param></cgq:execommandHTTP></soapenv:Body></soapenv:Envelope>";
        
        //let urlString = "http://192.168.1.100:8084/WSCmdSequoia/WSSequoia"
        let urlString = "http://192.168.2.135:8080/WSCmdSequoia/WSSequoia"
        
        let url = NSURL(string: urlString)
        let theRequest = NSMutableURLRequest(URL: url!)
        let msgLength = soapMessage.characters.count
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        theRequest.addValue(String(msgLength), forHTTPHeaderField: "Content-Length")
        theRequest.HTTPMethod = "POST"
        theRequest.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) // or false
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(theRequest) { (data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void in
            
            guard error == nil else {
                print("error : \(error?.description)")
                return
            }
            
            
            dispatch_async(dispatch_get_main_queue(), {
                var parser: NSXMLParser = NSXMLParser()
                parser = NSXMLParser(data: data!)
                print("data : \(data)")
                parser.delegate = self
                parser.parse()
            })
        }
        
        task.resume()
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?){
        //currentcomd = elementName;
    }
    
    func parser(parser: NSXMLParser, foundComment comment: String){
        //if ( currentcomd == "return"){
        //    txtres.text = comment;
        //}
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        let data = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (!data.isEmpty) {
            //if (data != "\r"){
                //let tmp =
                //self.txtres.text = self.txtres.text + data + "\n"
                //self.txtres.text = tmp
            //}
            //if ( currentcomd == "return"){
                //if (data != "\r"){
                    //txtres.text = txtres.text + data //+ "\n";
                //}
            //}
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
