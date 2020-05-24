//
//  ResetPasswordViewController.swift
//  YouniqueMusic
//
//  Created by xww on 5/1/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase
class ResetPasswordViewController: UIViewController {

    @IBOutlet var emailField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let email = ""
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func doneAction(_ sender: Any) {
        guard let email = emailField.text else {
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if error == nil {
                let msg = "A reset link has already sent to your email!"
                let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                let action1 = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action1)
                self.present(alert,animated: true,completion: nil)
                
            } else {
                let alert = UIAlertController(title: nil, message: error?.localizedDescription, preferredStyle: .alert)
                  let action1 = UIAlertAction(title: "OK", style: .default, handler: nil)
                  alert.addAction(action1)
                  self.present(alert,animated: true,completion: nil)
        
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
