
import UIKit
import FBSDKLoginKit
import Firebase
import AWSCognito
import AWSLambda
import UserNotifications
import SVProgressHUD
import FBSDKCoreKit

class LoginVC: UIViewController {
  
  @IBOutlet weak var fbLogInBtn: UIButton!
  
  private var ref: FIRDatabaseReference!
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder);
  }
  
  // MARK: UIViewController overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Initialize Firebase database ref.
    ref = FIRDatabase.database().reference()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // Set Facebook button Title
    if ((FBSDKAccessToken.current() != nil)) {
      fbLogInBtn.setTitle("LOG OUT", for: .normal)
      logInUser()
    } else {
      fbLogInBtn.setTitle("LOG IN WITH FACEBOOK", for: .normal)
    }
  }
  
  // MARK: Helper methods
  
  func logInUser() {
    
    SVProgressHUD.show()
    
    // Attempt a log in.
    User.shared.logIn(
      successBlock: {
        
        // Upsert the user's Firebase ID onto the backend.
        User.shared.upsertFirebaseId(successBlock: nil, failureBlock: nil, finallyBlock: nil)
        
        // Upsert the device token onto the backend - if the user has already authorized remote notification.
        UNUserNotificationCenter.current().getNotificationSettings {
          (settings) in
          if settings.authorizationStatus == .authorized {
            // Request authorization so the latest device token get read and upserted into the backend.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.requestAuthorization(successBlock: nil, failureBlock: nil, finallyBlock: nil)
          }
        }
        
        DispatchQueue.main.async {
          self.showNextViewController()
        }
      }, failureBlock: {
        (error) in
        // Log out the user.
        User.shared.logout()
        
        // Alert.
        DispatchQueue.main.async {
          self.showLogoutFailureAlert()
        }
      }, finallyBlock: {
        // Update UI.
        DispatchQueue.main.async {
          SVProgressHUD.dismiss()
        }
      }
    )
  }
  
  func showLogoutFailureAlert() {
    // Show log out failure alert.
    let alert = UIAlertController(
      title: "Failure",
      message: "Unable to Log Into App",
      preferredStyle: .alert)
    
    // Handle "OK" action.
    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(ok)
    
    // Present alert.
    present(alert, animated: true, completion: nil)
  }
  
  func showLogoutConfirmationAlert() {
    // Show log out alert.
    let alert = UIAlertController(
      title: "Confirmation",
      message: "Are you sure you want to log out?",
      preferredStyle: UIAlertControllerStyle.alert
    )
    
    // Handle "OK" action.
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
      action in
      FBSDKLoginManager().logOut()
      FBSDKAccessToken.setCurrent(nil) // Set "none" currently logged in user.
      self.fbLogInBtn.setTitle("LOG IN WITH FACEBOOK", for: .normal)
    }))
    
    // Handle "Cancel" action.
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
      action in
      // Do nothing.
    }))
    
    // Present alert.
    present(alert, animated: true, completion: nil)
  }
  
  func showNextViewController() {
    UNUserNotificationCenter.current().getNotificationSettings {
      (settings) in
      if settings.authorizationStatus == .notDetermined ||
        settings.authorizationStatus == .denied {
        // Remote notification not authorized.
        DispatchQueue.main.async {
          self.performSegue(withIdentifier: "RemoteNotificationSegue", sender: self)
        }
      } else {
        // Remote notification is authorized.
        
        // CONTINUE FROM HERE
        // Find out if the user has an existing phone number.
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
          // Get user value
          let value = snapshot.value as? NSDictionary
          let phoneNumber = value?["phoneNumber"] as? String ?? ""
          if phoneNumber == ""
          {
            // Show register flow.
            DispatchQueue.main.async {
              self.performSegue(withIdentifier: "RegisterSegue", sender: self)
            }
          }else{
            // Show radar flow.
            DispatchQueue.main.async {
              self.performSegue(withIdentifier: "tabbarSegue", sender: self)
            }
          }
          
          // ...
        }) { (error) in
          print(error.localizedDescription)
        }

        
        // The user has an existing number; find out if the user still owns this phone number.
        
        // The user owns his phone number; show radar screen.
        
        // The user does not own his phone number; show phone number registration flow.
        
        // The user does not have an existing number: show phone number registration flow.
        
      }
    }
  }
  
  // MARK: Storyboard methods
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
  }
  
  // MARK: Segue unwind methods
  
  @IBAction func logout(unwindSegue: UIStoryboardSegue) {
    User.shared.logout()
  }
  
  // MARK: Action methods
  
  @IBAction func fbLogInButtonTouchedUpInside(_ sender: Any) {
    if FBSDKAccessToken.current() != nil {
      showLogoutConfirmationAlert()
    } else {
      FBSDKLoginManager().logIn(withReadPermissions: ["email"], from: self) {
        (result, error) in
        if error == nil && result != nil {
          // Success.
          let logInResult = result! as FBSDKLoginManagerLoginResult
          if let permissions = logInResult.grantedPermissions {
            if permissions.contains("email") {
              // We have all the permissions we need.
              
              print("Log in successful.")
            }
          }
        }
      }
    }
  }
}
