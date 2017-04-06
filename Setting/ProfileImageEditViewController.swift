
import UIKit

class ProfileImageEditViewController: UIViewController, UIActionSheetDelegate {

  @IBOutlet weak var editBtn: UIButton!
  @IBOutlet weak var profileImageView: UIImageView!
  
  var currentProfileImage : UIImage!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    profileImageView.image = currentProfileImage
      // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
    

  // MARK : ACTIONS
  @IBAction func editButtonTouchedUpInside(_ sender: Any) {
    let actionSheetController: UIAlertController = UIAlertController(title: "", message: "Choose", preferredStyle: .actionSheet)
    
    let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
      print("Cancel")
    }
    actionSheetController.addAction(cancelActionButton)
    
    
    let deleteActionButton: UIAlertAction = UIAlertAction(title: "Delete Photo", style: .default)
    { action -> Void in
      print("Delete")
    }
    actionSheetController.addAction(deleteActionButton)
    
    let TakeActionButton: UIAlertAction = UIAlertAction(title: "Take Photo", style: .default)
    { action -> Void in
      print("Take")
    }
    actionSheetController.addAction(TakeActionButton)
    
    let SelectActionButton: UIAlertAction = UIAlertAction(title: "Select Photo", style: .default)
    { action -> Void in
      print("Select")
    }
    actionSheetController.addAction(SelectActionButton)
    
    self.present(actionSheetController, animated: true, completion: nil)
  }
  
  @IBAction func backButtonTouchedUpInside(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

}
