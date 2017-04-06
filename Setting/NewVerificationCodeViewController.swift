

import UIKit
import SVProgressHUD
import AWSLambda
import Firebase
import UXPasscodeField

class NewVerificationCodeViewController: UIViewController {

  private var ref: FIRDatabaseReference!
  
  let requestInterval = 60
  
  var areaCode: String?
  var phoneNumber: String?
  var secondsLeft: Int?
  
  @IBOutlet weak var pincodeTF: UXPasscodeField!
  @IBOutlet weak var phonenumberLbl: UILabel!
  @IBOutlet weak var resendBtn: UIButton!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    pincodeTF.becomeFirstResponder()
    
    pincodeTF.addTarget(self, action: #selector(NewVerificationCodeViewController.pincodeFieldDidChangeValue), for: .valueChanged)
    
    
    self.phonenumberLbl.text = "+\(self.areaCode! as String) \(self.phoneNumber! as String)"
  
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
    

  @IBAction func viewTapped(_ sender: Any) {
    if pincodeTF.passcode.characters.count == 6
    {
      self.view.endEditing(true)
    }
  }
  
  @IBAction func pincodeFieldTouchedUpInside(_ sender: Any) {
    pincodeTF.becomeFirstResponder()
  }
  
  @IBAction func pincodeFieldDidChangeValue() {
    if pincodeTF.passcode.characters.count == 6
    {
      resendBtn.setTitle("DONE", for: .normal)
    }else{
      resendBtn.setTitle("RESEND", for: .normal)
    }
    print(pincodeTF.passcode)
  }
  
  @IBAction func backButtonTouchedUpInside(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
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
  
  @IBAction func resendButtonTouchedUpInside(_ sender: Any) {
    
    if resendBtn.titleLabel?.text == "RESEND"
    {
      if self.phonenumberLbl.text == "+555 555555555555555" {
        self.pincodeTF.becomeFirstResponder()
        return
      }
      
//      SVProgressHUD.show()
//      
//      // Request for verification code.
//      let function = "arn:aws:lambda:us-east-1:102863130548:function:RequestVerificationCode:REL1"
//      let payload = [
//        "AreaCode": "+\(self.areaCode!)",
//        "PhoneNumber": self.phoneNumber!
//      ]
//      let invoker = AWSLambdaInvoker.default()
//      invoker.invokeFunction(function, jsonObject: payload).continue({
//        (task) -> Any? in
//        
//        self.pincodeTF.becomeFirstResponder()
//        
//        // Hide progress indicator.
//        DispatchQueue.main.sync {
//          SVProgressHUD.dismiss()
//        }
//        
//        return nil
//      })
    }else{
      let verificationCode = pincodeTF.passcode
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
//              self.performSegue(withIdentifier: "", sender: self)
            }
          } else if task.result?["VerificationStatus"] == "Expired" {
            // Verification code has expired.
            self.secondsLeft = 0 // Enable "resend verification code" button.
            self.resendBtn.setTitle("RESEND", for: .normal)
            
            self.showAlert(
              title: "Phone Number Activation",
              body: "Please request for another verification code and try again.")
          } else if task.result?["VerificationStatus"] == "Invalid" {
            // Verification code is invalid.
            self.resendBtn.setTitle("RESEND", for: .normal)
            
            self.showAlert(
              title: "Phone Number Activation",
              body: "This is an invalid code, please check again and enter the code")
          } else if task.result?["VerificationStatus"] == "Failure" {
            // Verification failed.
            self.resendBtn.setTitle("RESEND", for: .normal)
            
            self.showAlert(
              title: "Phone Number Activation",
              body: "This is an invalid code, please check again and enter the code.")
          }
        } else if task.result?["Status"] == "Failure" {
          // Phone number verification operation failure.
          self.resendBtn.setTitle("RESEND", for: .normal)
          
          self.showAlert(
            title: "Phone Number Activation",
            body: "This is an invalid code, please check again and enter the code.")
        } else {
          // Phone number verification operation failure.
          self.resendBtn.setTitle("RESEND", for: .normal)
          
          self.showAlert(
            title: "Phone Number Activation",
            body: "This is an invalid code, please check again and enter the code.")
        }
        
        // Hide progress indicator.
        DispatchQueue.main.sync {
          SVProgressHUD.dismiss()
        }
        
        return nil
      })
    }
    
  }
  
}
