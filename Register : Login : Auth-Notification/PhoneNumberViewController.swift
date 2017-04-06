

import UIKit
import AWSLambda
import SVProgressHUD

// TODO:
//  - Rename to "PhoneNumberVC".
class PhoneNumberViewController: UIViewController,
  UITextFieldDelegate {
  
  @IBOutlet weak var areaCodeTF: UITextField!
  @IBOutlet weak var phoneNumberTF: UITextField!
  @IBOutlet weak var requestBtn: UIButton!
  @IBOutlet weak var logoutBtn: UIBarButtonItem!
  
  // MARK: UIViewController overrides
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Enable textfields and button - in case they are disabled.
    self.areaCodeTF.isEnabled = true
    self.phoneNumberTF.isEnabled = true
    self.requestBtn.isEnabled = true
    
    // Disable the request button if the textfields are not filled.
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
  
  // MARK: Action methods
  
  @IBAction func viewTapped(_ sender: AnyObject) {
    self.view.endEditing(true)
  }
  
  func enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled() {
    if self.areaCodeTF.text!.characters.count > 0 &&
      self.phoneNumberTF.text!.characters.count > 0 {
      self.requestBtn.isEnabled = true
    } else {
      self.requestBtn.isEnabled = false
    }
  }
  
  @IBAction func areaCodeEditingDidChanged() {
    self.enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled()
  }
  
  @IBAction func phoneNumberEditingDidChanged() {
    self.enableRequestButtonIfAreaCodeAndPhoneNumberAreFilled()
  }
  
  @IBAction func requestVerificationCode() {
    
    SVProgressHUD.show()
    
    // Disable textfields and button.
    self.areaCodeTF.isEnabled = false
    self.phoneNumberTF.isEnabled = false
    self.requestBtn.isEnabled = false
    
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
          self.performSegue(withIdentifier: "VerificationCodeSegue", sender: self)
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
          self.requestBtn.isEnabled = true
        }
      }
      
      // Hide progress indicator.
      DispatchQueue.main.sync {
        SVProgressHUD.dismiss()
      }
      
      return nil
    })
  }
  
  // MARK: Storyboard methods
  
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    self.view.endEditing(true)
    return true
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "VerificationCodeSegue" {
      let vc = segue.destination as! VerificationCodeViewController
      vc.areaCode = self.areaCodeTF.text
      vc.phoneNumber = self.phoneNumberTF.text
    }
  }
  
  @IBAction func back(unwindSegue: UIStoryboardSegue) {
    // Do nothing.
  }
}

