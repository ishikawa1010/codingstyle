
import UIKit
import Firebase
import SVProgressHUD

class UserProfileViewController: UIViewController,
  UITextFieldDelegate {
  
  private let ref = FIRDatabase.database().reference()
  @IBOutlet weak var displayNameTF: UITextField!
  @IBOutlet weak var emailTF: UITextField!
  
  // MARK: UIViewController overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Read user's Facebook profile details through Firebase auth.
    let user = FIRAuth.auth()?.currentUser
    self.displayNameTF.text = user?.displayName
    self.emailTF.text = user?.email
    
    self.navigationItem.hidesBackButton = true
  }
  
  // MARK: UITextFieldDelegate methods overrides
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    if textField === self.displayNameTF {
      // Validate name text field.
      if self.displayNameTF.text!.characters.count >= 0 &&
        self.displayNameTF.text!.characters.count < 20 {
        return true
      }
      return false
    } else if textField == self.emailTF {
      // Validate email text field.
      if self.emailTF.text!.characters.count >= 0 &&
        self.emailTF.text!.characters.count < 20 {
        return true
      }
      return false
    }
    
    return false
  }
  
  // MARK: Action methods
  @IBAction func viewTapped(_ sender: Any) {
    self.view.endEditing(true)
  }
  
  @IBAction func done(_ sender: Any) {
    // Validate the format of the email.
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    if !emailTest.evaluate(with: self.emailTF.text!) {
      let alert = UIAlertController(
        title: "Email Format Invalid",
        message: "Make sure your email address matches the format \"name@domain.com\".",
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.navigationController?.present(alert, animated: true, completion: nil)
      return
    }
    
    // Update profile details.
    SVProgressHUD.show()
    FIRAuth.auth()?.currentUser?.updateEmail(self.emailTF.text!, completion: nil)
    let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
    changeRequest?.displayName = self.displayNameTF.text!
    changeRequest?.commitChanges(completion: {
      (error) in
      SVProgressHUD.dismiss()
      self.dismiss(animated: true, completion: nil)
    })
    
    // Write to Firebase.
    let lastLogin = NSDate()
    let value : [String: Any] = [
      "displayName": self.displayNameTF.text!,
      "email": self.emailTF.text!,
      "lastLogin": lastLogin.timeIntervalSince1970,
      "lastLoginReadable": lastLogin.description
    ]
    let child = self.ref.child("users/\(User.shared.firebaseId!)")
    child.updateChildValues(value)
  }
}


