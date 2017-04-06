

import UIKit
import SVProgressHUD
import AWSLambda
import Firebase

// TODO:
//  - Rename to "VerificationCodeVC".
class VerificationCodeViewController: UIViewController,
  UITextFieldDelegate {
  
  private var ref: FIRDatabaseReference!
  
  let requestInterval = 60
  
  var areaCode: String?
  var phoneNumber: String?
  var secondsLeft: Int?
  
  // TODO: rename.
  @IBOutlet weak var phoneNumberLbl: UILabel!
  @IBOutlet weak var resendBtn: UIButton!
  @IBOutlet weak var verifyPhoneNumberBtn: UIButton!
  
  // Pin code fields.
  @IBOutlet weak var pinCode1TF: UITextField!
  @IBOutlet weak var pinCode2TF: UITextField!
  @IBOutlet weak var pinCode3TF: UITextField!
  @IBOutlet weak var pinCode4TF: UITextField!
  @IBOutlet weak var pinCode5TF: UITextField!
  @IBOutlet weak var pinCode6TF: UITextField!
  
  var pinCodeFields: [UITextField]
  
  required init?(coder aDecoder: NSCoder) {
    // Initialize Firebase database ref.
    self.ref = FIRDatabase.database().reference()
    
    self.pinCodeFields = []
    
    super.init(coder: aDecoder);
  }
  
  // MARK: UIViewController overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.phoneNumberLbl.text = "+\(self.areaCode! as String) \(self.phoneNumber! as String)"
    
    self.navigationItem.hidesBackButton = true
    self.resendBtn.isEnabled = false
    
    let oneSecond = TimeInterval(1)
    self.secondsLeft = self.requestInterval
    let _ = Timer.scheduledTimer(withTimeInterval: oneSecond, repeats: true, block: {
      (timer) in
      self.setResendButtonText()
    })
    
    self.pinCode1TF.delegate = self
    self.pinCode2TF.delegate = self
    self.pinCode3TF.delegate = self
    self.pinCode4TF.delegate = self
    self.pinCode5TF.delegate = self
    self.pinCode6TF.delegate = self
    
    self.pinCodeFields = [
      self.pinCode1TF,
      self.pinCode2TF,
      self.pinCode3TF,
      self.pinCode4TF,
      self.pinCode5TF,
      self.pinCode6TF
    ]
    
    // Disable button.
    self.enableOrDisableVerificationPhoneNumberButton()
  }
  
  // MARK: UITextFieldDelegate methods overrides
  
  func textField(_ textField: UITextField,
                 shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    
    // If this is one of the pin field.
    if textField == self.pinCode1TF || textField == self.pinCode2TF || textField == self.pinCode3TF ||
      textField == self.pinCode4TF || textField == self.pinCode5TF || textField == self.pinCode6TF {
      // A pin field is focused.
      
      // Find the index of this text field.
      let thisFieldIndex = self.pinCodeFields.index(where: { $0 === textField })
      
      // Find out if the replacement string (character) is a backspace.
      let char = string.cString(using: String.Encoding.utf8)!
      let isBackSpace = strcmp(char, "\\b")
      if isBackSpace == -92 && textField.text?.characters.count == 1 {
        // The replacement string (character) is a backspace and the pin field alrady has 1 digit.
        
        return true
      } else {
        // The replacement string (character) is not a backspace.
        
        // Helper function to focus on the next pin field if it exists. Returns true if the next
        // pin field exists.
        func focusNextPinFieldIfItExists(clearNextPinField: Bool) -> Bool {
          let exists = thisFieldIndex != nil && thisFieldIndex! != self.pinCodeFields.count-1
          
          // Focus on the next pin field (if it exists).
          if exists {
            let nextPinField = self.pinCodeFields[thisFieldIndex!+1]
            if clearNextPinField {
              nextPinField.text = ""
            }
            nextPinField.becomeFirstResponder()
          }
          
          return exists
        }
        
        if textField.text!.characters.count == 0 && range.location == 0 {
          // Pin field has no digit and the location is at the start.
          
          // Set the textfield text to the character.
          textField.text = string
          
          let _ = focusNextPinFieldIfItExists(clearNextPinField: false) // Focus on the next pin field.
          
          return false // Eat up the character so it does not populate the next pin field.
        } else if textField.text!.characters.count == 1 && range.location == 1 {
          // Pin field has 1 character and the location is at the end of the string.
          
          return focusNextPinFieldIfItExists(clearNextPinField: true) // Focus on the next pin field and set the digit there.
        }
      }
      
      // Enforce character limit - do not allow the character to be returned.
      if textField.text!.characters.count >= 1 {
        return false
      }
    }

    // Disallow if the input is not from a pin field on the screen.
    return false
  }
  
  func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
    self.enableOrDisableVerificationPhoneNumberButton()
  }
  

  // MARK: Helper methods
  
  func setResendButtonText() {
    if self.secondsLeft! > 0 {
      // Counting down.
      self.secondsLeft! -= 1
      let minsLeft = Int(self.secondsLeft! / 60)
      let modSecsLeft = self.secondsLeft! % 60
        
        self.resendBtn.setBackgroundImage(UIImage(named:"timecounterbutton"), for: .normal)
      self.resendBtn.setTitle("\(minsLeft):\(modSecsLeft)", for: .normal)
        self.resendBtn.titleLabel?.textColor =
            UIColor.init(red: 133/255, green: 178/255, blue: 0/255, alpha: 1.0)
      self.resendBtn.isEnabled = false
    } else {
      // Countdown finished.
      self.resendBtn.setBackgroundImage(UIImage(named:"requestbutton"), for: .normal)
      self.resendBtn.setTitle("RESEND", for: .normal)
        self.resendBtn.titleLabel?.textColor = UIColor.white
        self.resendBtn.isEnabled = true
        
    }
  }
  
  func showAlert(title: String, body: String) {
    DispatchQueue.main.sync {
      let alert = UIAlertController(
        title: title,
        message: body,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.navigationController?.present(alert, animated: true, completion: nil)
    }
  }
  
  func enableOrDisableVerificationPhoneNumberButton() {
    for pinCodeField in self.pinCodeFields {
      if pinCodeField.text?.characters.count != 1 {
        self.verifyPhoneNumberBtn.isEnabled = false
        return
      }
    }
    
    self.verifyPhoneNumberBtn.isEnabled = true
  }
  
  // MARK: Action methods
  
  @IBAction func viewTapped() {
    self.view.endEditing(true)
  }
  
  @IBAction func resendCode() {
    SVProgressHUD.show()
    
    // Request for verification code.
    let function = "arn:aws:lambda:us-east-1:102863130548:function:RequestVerificationCode:REL1"
    let payload = [
      "AreaCode": "+\(self.areaCode!)",
      "PhoneNumber": self.phoneNumber!
    ]
    let invoker = AWSLambdaInvoker.default()
    invoker.invokeFunction(function, jsonObject: payload).continue({
      (task) -> Any? in
      
      self.secondsLeft = self.requestInterval
      
      // Hide progress indicator.
      DispatchQueue.main.sync {
        self.setResendButtonText()
        SVProgressHUD.dismiss()
      }
      
      return nil
    })
  }
  
  @IBAction func verifyPhoneNumber() {
    
    let verificationCode = "\(self.pinCode1TF.text! as String)\(self.pinCode2TF.text! as String)\(self.pinCode3TF.text! as String)\(self.pinCode4TF.text! as String)\(self.pinCode5TF.text! as String)\(self.pinCode6TF.text! as String)"
    
    if verificationCode == "555555" {
      // Bypass code input. Segue immediately.
      self.ref.child("users/\(User.shared.firebaseId!)/phoneNumber").setValue(self.phoneNumber!)
      self.performSegue(withIdentifier: "UserProfileSegue", sender: self)
      return
    }
    
    SVProgressHUD.show()
    
    // Request for verification code.
    let function = "arn:aws:lambda:us-east-1:102863130548:function:VerifyPhoneNumber:REL1"
    let payload = [
      "AreaCode": "+\(self.areaCode!)",
      "PhoneNumber": self.phoneNumber!,
      "VerificationCode": verificationCode
    ]
    let invoker = AWSLambdaInvoker.default()
    invoker.invokeFunction(function, jsonObject: payload).continue({
      (task) -> AnyObject? in
      
      if task.result?["Status"] == "Success" {
        // Phone number verification operation successful (note: operation).
        
        if task.result?["VerificationStatus"] == "Success" {
          // Verification successful.
          DispatchQueue.main.sync {
            // Set phone number in Firebase.
            self.ref.child("users/\(User.shared.firebaseId!)/phoneNumber").setValue(self.phoneNumber!)
            
            // Segue.
            self.performSegue(withIdentifier: "UserProfileSegue", sender: self)
          }
        } else if task.result?["VerificationStatus"] == "Expired" {
          // Verification code has expired.
          self.secondsLeft = 0 // Enable "resend verification code" button.
          self.showAlert(
            title: "Verification Code Expired",
            body: "Please request for another verification code and try again.")
        } else if task.result?["VerificationStatus"] == "Invalid" {
          // Verification code is invalid.
          self.showAlert(
            title: "Invalid Verification Code",
            body: "Please check your verification code and try again.")
        } else if task.result?["VerificationStatus"] == "Failure" {
          // Verification failed.
          self.showAlert(
            title: "Verification Failure",
            body: "Please check your verification code and try again.")
        }
      } else if task.result?["Status"] == "Failure" {
        // Phone number verification operation failure.
        self.showAlert(
          title: "Verification Failure",
          body: "Please check your verification code and try again.")
      } else {
        // Phone number verification operation failure.
        self.showAlert(
          title: "Verification Failure",
          body: "Please check your verification code and try again.")
      }
      
      // Hide progress indicator.
      DispatchQueue.main.sync {
        self.setResendButtonText()
        SVProgressHUD.dismiss()
      }
      
      return nil
    })
  }
  
  
  // MARK: Storyboard methods
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

  }
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    self.view.endEditing(true)
    return true
  }
}
