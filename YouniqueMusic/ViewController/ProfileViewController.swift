//
//  ProfileViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    var genderPickerData: [String] = ["female", "male", "other"]
    var profileImageUrl: String?
    var username: String?
    var email: String?
    
    @IBOutlet var addButton: UIButton!
    let updateAlert = UIAlertController(title: "updating info...",
    message: nil, preferredStyle: .alert)
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameTextField: UITextField!
    
    @IBOutlet var genderButton: UIButton!
    
    @IBOutlet var birthdayButton: UIButton!
    @IBOutlet var datePicker: UIDatePicker!
    
    @IBOutlet var genderPicker: UIPickerView!
    @IBOutlet var chooseButton: UIButton!
    
    @IBOutlet var emailLabel: UILabel!
    
    @IBOutlet var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserProfile()
        setGenderPicker()
        setNav()
        profileImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        addButton.addTarget(self, action: #selector(handleSelectProfileImageView), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(handleUpdate), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.isHidden = false
        }
    }
    
    func setNav() {
        let item1=UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action:#selector(handleUpdate))
        self.navigationItem.rightBarButtonItem = item1
    }
    
    func setGenderPicker(){
        genderPicker.delegate = self
        genderPicker.dataSource = self
        datePicker.backgroundColor = .white
        datePicker.setValue(UIColor.blue, forKey: "textColor")
        genderPicker.setValue(UIColor.blue, forKey: "textColor")
    }
    
    
    @IBAction func signOut(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            self.showMsgAlert(msg: "Haven't log in")
        }
        
        do {
            try Auth.auth().signOut()
            self.showMsgAlert(msg: "Sign Out Successfully")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.loggedIn = false;
            let storyboard = UIStoryboard(name: "Basic", bundle: nil)
            let controller = storyboard.instantiateViewController(identifier: "guideID") as GuideViewController
            appDelegate.window?.rootViewController = controller
            self.navigationController?.popToRootViewController(animated: true)
            
        } catch let error as NSError {
            self.showMsgAlert(msg: error.localizedDescription)
        }
    }
    
    func showMsgAlert(msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action1)
        self.present(alert,animated: true,completion: nil)
        return
    }
    
    @IBAction func selectGender(_ sender: Any) {
        genderPicker.isHidden = false
        chooseButton.isHidden = false
    }
    
    
    @IBAction func selectBirthday(_ sender: Any) {
        datePicker.isHidden = false
        chooseButton.isHidden = false
    }
    
    
    @IBAction func chooseAction(_ sender: Any) {
        if(!datePicker.isHidden) {
            let date = datePicker.date
            let dformatter = DateFormatter()
            dformatter.dateFormat = "yyyy-MM-dd"
            let datestr = dformatter.string(from: date)
            print(datestr)
            birthdayButton.setTitle(datestr, for:[])
            datePicker.isHidden = true
        } else if (!genderPicker.isHidden) {
            genderPicker.isHidden = true
        }
        
        chooseButton.isHidden = true
    }
    
    //update information
    @objc func handleUpdate() {
        if let name = usernameTextField.text {
            if name.count > 20 || name.count <= 0 {
                let alert = UIAlertController(title: "username length must smaller than 20 and more than 0", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
                return
            }
        }
        self.present(updateAlert, animated: true, completion: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard let uid = Auth.auth().currentUser?.uid else{
            let alertController = UIAlertController(title: "Haven't log in!",
            message: nil, preferredStyle: .alert)
            self.present(alertController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
            return
        }
        //successfully authenticated user
        
        // upload profile image
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
        
        // Compress Image into JPEG type
        if let profileImage = self.profileImage.image, let uploadData = profileImage.jpegData(compressionQuality: 0.1) {

            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if(error != nil){
                    print(error ?? "Error when uploading profile image")
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                            print(error)
                    } else {
                        self.profileImageUrl = url?.absoluteString
                        self.registerUserIntoDatabaseWithUID(uid)
                    }
                }
            })
        }
    }
    
    @IBAction func clickBackground(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    fileprivate func registerUserIntoDatabaseWithUID(_ uid: String) {
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        let playlistRef = ref.child("playlist").child(uid)
        let username = usernameTextField.text
        let email = emailLabel.text
        let gender = genderButton.titleLabel?.text
        let birthday = birthdayButton.titleLabel?.text
        let url = profileImageUrl
        let values = ["username": username ?? uid, "email": email, "gender": gender, "birthday": birthday, "profileurl": url] as [String : AnyObject]
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            if self.presentedViewController != nil {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            playlistRef.child("favourite playlist").setValue([:])
            playlistRef.child("history").setValue([:])
            self.dismiss(animated: true, completion: nil)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController?.viewDidLoad()
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = UserInfo(dictionary: dictionary)
                self.setupProfileWithUser(user)
                print(user)
            }
            
        }, withCancel: nil)
    }

    func setupProfileWithUser(_ user: UserInfo) {
        username = user.username
        if let url = user.profileurl {
            profileImage.downloadImageUsingCacheWithLink(url)
        }
        if let name = user.username {
            usernameTextField.text = name
        }
        if let email = user.email {
            emailLabel.text = email
        }
        if let date = user.birthday {
            birthdayButton.setTitle(date, for:[])
        }
        if let gender = user.gender {
            genderButton.titleLabel?.text = gender
        }
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImage.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
    
}

extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource  {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.genderPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderButton.setTitle(genderPickerData[row], for: [])
    }
    
}


fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

extension UIImageView {
    
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
        }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
    
    func downloadImageUsingCacheWithLink(_ urlLink: String){
        self.image = nil
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if urlLink.isEmpty {
            return
        }
        // check cache first
        if let cachedImage = appDelegate.imageCache.object(forKey: urlLink as NSString) {
            self.image = cachedImage
            return
        }
        
        // otherwise, download
        if let url = URL(string: urlLink) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if let err = error {
                    print(err)
                    return
                }
                DispatchQueue.main.async {
                    if let newImage = UIImage(data: data!) {
                        appDelegate.imageCache.setObject(newImage, forKey: urlLink as NSString)
                        
                        self.image = newImage
                    }
                }
            }).resume()
        }
    }
    
}
