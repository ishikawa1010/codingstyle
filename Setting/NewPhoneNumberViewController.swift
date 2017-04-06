
import UIKit
import AWSLambda
import SVProgressHUD
import Firebase

class NewPhoneNumberViewController: UIViewController, UITextFieldDelegate {

  @IBOutlet weak var oldphonenumberLbl: UILabel!
  @IBOutlet weak var areaCodeTF: UITextField!
  @IBOutlet weak var phoneNumberTF: UITextField!
  
  @IBOutlet weak var nextBtn: UIButton!
  @IBOutlet weak var nextBtnBottom: NSLayoutConstraint!
  
  private var ref: FIRDatabaseReference!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.areaCodeTF.isEnabled = true
    self.phoneNumberTF.isEnabled = true
    self.nextBtn.isEnabled = false
    
    // Initialize Firebase database ref.
    ref = FIRDatabase.database().reference()
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
      // Get user value
      let value = snapshot.value as? NSDictionary
      let phoneNumber = value?["phoneNumber"] as? String ?? ""
      self.oldphonenumberLbl.text = "+" + phoneNumber
      
      // ...
    }) { (error) in
      print(error.localizedDescription)
    }
    
    
    NotificationCenter.default.addObserver(self, selector: #selector(UpdateStatusViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(UpdateStatusViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
  }

  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.isNavigationBarHidden = true
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled() {
    if self.areaCodeTF.text!.characters.count > 0 &&
      self.phoneNumberTF.text!.characters.count > 0 {
      self.nextBtn.isEnabled = true
    } else {
      self.nextBtn.isEnabled = false
    }
  }
  
  @IBAction func areaCodeEditingDidChanged() {
    self.enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled()
  }
  
  @IBAction func phoneNumberEditingDidChanged() {
    self.enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled()
  }
  
  // MARK: UITextFieldDelegate methods overrides
  
  func textField(_ textField: UITextField,
                 shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    
    // Allow backspace.
    // We need to explicitly allow backspace because we are not able to delete when the character
    // limit is reached.
    let char = string.cString(using: String.Encoding.utf8)!
    let isBackSpace = strcmp(char, "\\b")
    if (isBackSpace == -92) {
      return true
    }
    
    // Enforce textfield length.
    
    var maxChar = -1
    if textField === self.areaCodeTF {
      maxChar = 3
    } else if textField == self.phoneNumberTF {
      maxChar = 15
    }
    if maxChar != -1 {
      return !(textField.text!.characters.count >= maxChar)
    }
    
    return true
  }
  
  //MARK TAP ACTION
  @IBAction func viewTapped(_ sender: Any) {
    self.view.endEditing(true)
  }
  
  // MARK : KEYBOARD
  func keyboardWillHide(_ sender: Notification) {
    if let userInfo = (sender as NSNotification).userInfo {
      if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
        //key point 0,
        self.nextBtnBottom.constant =  0
        //textViewBottomConstraint.constant = keyboardHeight
        UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
      }
    }
  }
  
  func keyboardWillShow(_ sender: Notification) {
    if let userInfo = (sender as NSNotification).userInfo {
      if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
        self.nextBtnBottom.constant = keyboardHeight
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
          self.view.layoutIfNeeded()
        })
      }
    }
  }
  
  
  // MARK : BUTTON ACTIONS
  @IBAction func nextButtonTouchedUpInside(_ sender: Any) {
    if self.areaCodeTF.text! == "555" && self.phoneNumberTF.text! == "555555555555555" {
      // Bypass code entered.
      self.performSegue(withIdentifier: "NewVerificationCodeSegue", sender: self)
      return
    }
    
    SVProgressHUD.show()
    
    // Disable textfields and button.
    self.areaCodeTF.isEnabled = false
    self.phoneNumberTF.isEnabled = false
    self.nextBtn.isEnabled = false
    
    // Request for verification code.
    let function = "arn:aws:lambda:us-east-1:102863130548:function:RequestVerificationCode:REL1"
    let payload = [
      "AreaCode": "+\(self.areaCodeTF.text!)",
      "PhoneNumber": self.phoneNumberTF.text!
    ]
    let invoker = AWSLambdaInvoker.default()
    invoker.invokeFunction(function, jsonObject: payload).continue({
      (task) -> Any? in
      if task.result?["Status"] == "Success" {
        // Request verification code successfully.
        DispatchQueue.main.sync {
          // Segue to the next screen.
          self.performSegue(withIdentifier: "NewVerificationCodeSegue", sender: self)
        }
      } else if task.result?["Status"] == "Failure" {
        // Request verification code failure.
        DispatchQueue.main.sync {
          // Show alert.
          let alert = UIAlertController(
            title: "Failure to Obtain Verification Code",
            message: "Please check your area code and try again.",
            preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          self.navigationController?.present(alert, animated: true, completion: nil)
          
          // Re-enable textfields and button.
          self.areaCodeTF.isEnabled = true
          self.phoneNumberTF.isEnabled = true
          self.nextBtn.isEnabled = true
        }
      }
      
      // Hide progress indicator.
      DispatchQueue.main.sync {
        SVProgressHUD.dismiss()
      }
      
      return nil
    })
  }
  
  
  @IBAction func backButtonTouchedUpInside(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  // MARK: Storyboard methods
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    self.view.endEditing(true)
    return true
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "NewVerificationCodeSegue" {
      let vc = segue.destination as! NewVerificationCodeViewController
      vc.areaCode = self.areaCodeTF.text
      vc.phoneNumber = self.phoneNumberTF.text
    }
  }
  
  
}
