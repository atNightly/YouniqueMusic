//
//  LoginViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseDatabase
class LoginViewController: UIViewController {


    @IBOutlet var passwordField: UITextField!
    @IBOutlet var emailField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func touchBackground(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func doneLogin(_ sender: Any) {
        if self.emailField.text == "" || self.passwordField.text == "" {
            self.showMsgAlert(msg: "Please type in email and pasword")
            return
        }

        Auth.auth().signIn(withEmail: self.emailField.text!, password: self.passwordField.text!) { (user, error) in
            
            if error != nil {
                self.showMsgAlert(msg: (error?.localizedDescription)!)
                return
            }
            
            self.showMsgAlert(msg: "Login Success")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.loggedIn = true
            appDelegate.window?.rootViewController = RootTabBarController()
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
    func clearContent() {
        emailField.text = ""
        passwordField.text = ""
        
    }
    @IBAction func returnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resetPassword(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "reset") as ResetPasswordViewController
        present(controller, animated: true, completion: nil)
    }
    
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
