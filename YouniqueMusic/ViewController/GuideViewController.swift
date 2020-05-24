//
//  GuideViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func signUpAction(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "SignUpID") as SignUpViewController
        //self.navigationController?.pushViewController(controller, animated: true)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "loginID") as LoginViewController
        present(controller, animated: true, completion: nil)
    }
}
