
import UIKit
import Firebase
import SVProgressHUD

class UpdateProfileViewController: UIViewController, UITextFieldDelegate {

  private let ref = FIRDatabase.database().reference()
  
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameTF: UITextField!
  @IBOutlet weak var emailTF: UITextField!
  @IBOutlet weak var updateprofileBtn: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let user = FIRAuth.auth()?.currentUser
    nameTF.text = user?.displayName
    emailTF.text = user?.email
    
    profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
    let data = NSData(contentsOf: (user?.photoURL)!)
    profileImageView.image = UIImage(data : data as! Data)
    
    updateprofileBtn.isEnabled = false
    
  }

  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.isNavigationBarHidden = true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  // MARK: UITextFieldDelegate methods overrides
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    
    updateprofileBtn.isEnabled = true
    updateprofileBtn.setBackgroundImage(UIImage(named: "requestbutton"), for: .normal)
    updateprofileBtn.setTitleColor(.white, for: .normal)
    return true
  }
  

  // MARK : TAP ACTIONS
  @IBAction func viewTapped(_ sender: Any) {
    self.view.endEditing(true)
  }
  
  // MARK : BUTTON ACTIONS
  @IBAction func backButtonTouchedUpInside(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func updateprofileButtonTouchedUpInside(_ sender: Any) {
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
    changeRequest?.displayName = self.nameTF.text!
    changeRequest?.commitChanges(completion: {
      (error) in
      SVProgressHUD.dismiss()
      self.dismiss(animated: true, completion: nil)
    })
    
    // Write to Firebase.
    let lastLogin = NSDate()
    let value : [String: Any] = [
      "displayName": self.nameTF.text!,
      "email": self.emailTF.text!,
      "lastLogin": lastLogin.timeIntervalSince1970,
      "lastLoginReadable": lastLogin.description
    ]
    let child = self.ref.child("users/\(User.shared.firebaseId!)")
    child.updateChildValues(value)
  }
  
  @IBAction func editButtonTouchedUpInside(_ sender: Any) {
    let profileimageeditVC = self.storyboard?.instantiateViewController(withIdentifier: "ProfileImageEditViewController") as! ProfileImageEditViewController
    profileimageeditVC.currentProfileImage = profileImageView.image
//    self.present(profileimageeditVC, animated: true, completion: nil)
    self.navigationController?.pushViewController(profileimageeditVC, animated: true)
  }
  
}
