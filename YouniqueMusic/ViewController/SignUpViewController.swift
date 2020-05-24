//
//  SignUpViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class SignUpViewController: UIViewController {
    
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var confirmField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func touchBackground(_ sender: Any) {
        self.view.endEditing(true)
    }

    
    @IBAction func createUser(_ sender: Any) {
        
        if self.emailField.text == "" || self.passwordField.text == "" {
            self.showMsgAlert(msg: "Please type in email and password")
            return
        } else if self.passwordField.text != self.confirmField.text {
            self.showMsgAlert(msg: "Confirm password is not matched")
            return
        }
        
        Auth.auth().createUser(withEmail: self.emailField.text!, password: self.passwordField.text!) { (user, error) in
            
            if error != nil {
                self.showMsgAlert(msg: (error?.localizedDescription)!)
                return
            }
            
            let uid = Auth.auth().currentUser?.uid
            
            let ref = Database.database().reference()
            let usersReference = ref.child("users").child(uid ?? "")
            let email = self.emailField.text
            let values = ["username": "username", "email": email, "profileurl": "https://firebasestorage.googleapis.com/v0/b/youniquemusic-e7233.appspot.com/o/Group%201315%403x.JPEG?alt=media&token=fd279efc-0279-4d93-8832-caa10d7357d0"] as [String : AnyObject]
            
            usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                if err != nil {
                    print(err ?? "")
                    return
                }
            })
            self.showMsgAlert(msg: "Create User Success")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
               appDelegate.loggedIn = true
            appDelegate.isFirstTime = true
            appDelegate.window?.rootViewController = RootTabBarController()
            NotificationCenter.default.post(name: NSNotification.Name("profile"), object: nil, userInfo: ["isFirst": true])
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    
    func showMsgAlert(msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action1)
        self.present(alert,animated: true,completion: nil)
        return
    }
    
    @IBAction func returnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
