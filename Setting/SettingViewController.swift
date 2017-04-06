
import UIKit
import Firebase

class SettingViewController: UIViewController {

  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nameLbl: UILabel!
  @IBOutlet weak var emailLbl: UILabel!
  @IBOutlet weak var phonenumberLbl: UILabel!
  
  private var ref: FIRDatabaseReference!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let user = FIRAuth.auth()?.currentUser
    nameLbl.text = user?.displayName
    emailLbl.text = user?.email
    
    profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
    let data = NSData(contentsOf: (user?.photoURL)!)
    profileImageView.image = UIImage(data : data as! Data)
    
    // Initialize Firebase database ref.
    ref = FIRDatabase.database().reference()
    
    let userID = FIRAuth.auth()?.currentUser?.uid
    self.ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
      // Get user value
      let value = snapshot.value as? NSDictionary
      let phoneNumber = value?["phoneNumber"] as? String ?? ""
      self.phonenumberLbl.text = "+" + phoneNumber
      
      // ...
    }) { (error) in
      print(error.localizedDescription)
    }

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  // MARK : Button Actions
  @IBAction func updateprofileButtonTouchedUpInside(_ sender: UIButton) {
    DispatchQueue.main.async {
      self.performSegue(withIdentifier: "updateprofileSegue", sender: self)
    }
  }
  
  @IBAction func updatephonenumberButtonTouchedUpInside(_ sender: Any) {
    DispatchQueue.main.async {
      self.performSegue(withIdentifier: "updatephonenumberSegue", sender: self)
    }
  }
  
}
