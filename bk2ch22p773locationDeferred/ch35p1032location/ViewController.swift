
import UIKit
import CoreLocation

class ManagerHolder {
    let locman = CLLocationManager()
    var delegate : CLLocationManagerDelegate? {
        get {
            return self.locman.delegate
        }
        set {
            // set delegate _once_
            if self.locman.delegate == nil && newValue != nil {
                self.locman.delegate = newValue
                print("setting delegate!")
            }
        }
    }
    var doThisWhenAuthorized : (() -> ())?
    func checkForLocationAccess(always:Bool = false, andThen f: (()->())? = nil) {
        // no services? fail but try get alert
        guard CLLocationManager.locationServicesEnabled() else {
            print("no location services")
            self.locman.startUpdatingLocation()
            return
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            f?()
        case .notDetermined:
            self.doThisWhenAuthorized = f
            always ?
                self.locman.requestAlwaysAuthorization() :
                self.locman.requestWhenInUseAuthorization()
        case .restricted:
            // do nothing
            break
        case .denied:
            print("denied")
            // do nothing, or beg the user to authorize us in Settings
            break
        }
    }
}



class ViewController: UIViewController, CLLocationManagerDelegate {
    let managerHolder = ManagerHolder()
    var locman : CLLocationManager {
        return self.managerHolder.locman
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.managerHolder.delegate = self
    }
    @IBOutlet weak var tv: UITextView!
    
    var startTime : Date!
    var trying = false
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("did change auth: \(status.rawValue)")
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.managerHolder.doThisWhenAuthorized?()
            self.managerHolder.doThisWhenAuthorized = nil
        default: break
        }
    }
    
    @IBAction func doFindMe (_ sender: Any!) {
        self.managerHolder.checkForLocationAccess {
            if self.trying { return }
            self.trying = true
            self.locman.desiredAccuracy = kCLLocationAccuracyBest
            self.locman.activityType = .other
            self.locman.distanceFilter = kCLDistanceFilterNone
            self.startTime = nil
            self.locman.allowsBackgroundLocationUpdates = true
            self.print("starting")
            self.locman.startUpdatingLocation()
            self.s = ""
            var ob : Any = ""
            ob = NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) {
                _ in
                NotificationCenter.default.removeObserver(ob)
                if CLLocationManager.deferredLocationUpdatesAvailable() {
                    self.print("going into background: deferring")
                    self.locman.allowDeferredLocationUpdates(untilTraveled: CLLocationDistanceMax, timeout: 15)
                } else {
                    self.print("going into background but couldn't defer")
                }

            }
            
        }
    }
    
    @IBAction func stopTrying () {
        self.locman.stopUpdatingLocation()
        self.startTime = nil
        self.trying = false
        self.tv.text = self.s
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        if let error = error {
            print(error)
        }
        let state = UIApplication.shared.applicationState
        if state == .background {
            if CLLocationManager.deferredLocationUpdatesAvailable() {
                print("deferring")
                self.locman.allowDeferredLocationUpdates(untilTraveled: CLLocationDistanceMax, timeout: 15)
            } else {
                print("not able to defer")
            }
        }
    }
    
    let REQ_ACC : CLLocationAccuracy = 10
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("did update location ")
        let loc = locations.last!
        let acc = loc.horizontalAccuracy
        let coord = loc.coordinate
        print(acc)
        if acc < 0 || acc > REQ_ACC {
            return // wait for the next one
        }
        // got it
        print("\(Date()): You are at \(coord.latitude) \(coord.longitude)")
    }
    
    var s = ""
    
    func print(_ s: Any) {
        self.s = self.s + "\n" + String(describing:s)
    }


}
