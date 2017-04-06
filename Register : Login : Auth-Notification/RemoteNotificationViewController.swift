
import UIKit
import UserNotifications

// TODO:
//  - Rename to "RemoteNotificationVC".
class RemoteNotificationViewController: UIViewController {
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Dismiss this screen if the user has already authorized remote notifications. Stay on this
    // screen if the authorization status is undetermined.
    UNUserNotificationCenter.current().getNotificationSettings {
      (settings) in
      if settings.authorizationStatus == .denied {
        self.alertAuthorization()
      } else if settings.authorizationStatus == .authorized {
        self.dismiss(animated: true, completion: nil)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: Helper methods.
  
  func alertAuthorization() {
    // Authorization denied - prompt the user to grant permission in settings.
    let alert = UIAlertController(
      title: "Authorization Denied",
      message: "App requires remote notifications to work. Please authorize App to send remote notifications in the settings app.",
      preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(ok)
    self.present(alert, animated: true, completion: nil)
  }
  
  // MARK: Action methods.
  
  @IBAction func authorizeRemoteNotification(_ sender: AnyObject) {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    appDelegate.requestAuthorization(successBlock: {
        self.dismiss(animated: true, completion: nil)
      }, failureBlock: { (error) in
        DispatchQueue.main.async {
          self.alertAuthorization()
        }
      }, finallyBlock: nil)
  }
}

