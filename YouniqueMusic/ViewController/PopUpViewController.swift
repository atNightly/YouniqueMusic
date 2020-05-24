//
//  PopUpViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import NotificationCenter
import Firebase

enum PopMode {
    case delete
    case add
    case edit
    case addList
    case editList
    case none
}

protocol PopViewDelegate: NSObjectProtocol
{
    func postPlayingList(userInfo: UserInfo, text: String)
}

class PopUpViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var popUpView: UIView!
    @IBOutlet var commentView: UITextView!
    let ref = Database.database().reference()
    var row = 0
    var comments: [Comment] = []
    var type = PopMode.none
    var userInfo: UserInfo?
    var commentText: String?
    var mid = ""
    var cid = ""
    var pid = ""
    var indexPath = IndexPath(row: 0, section: 3)
    
    var delegate: PopViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentView.delegate = self
        if commentText == nil {
            commentText = ""
        }
        commentView.text = commentText
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        switch type {
        case .delete:
        titleLabel.text = ""
        
        case .add:
        titleLabel.text = "Add Comment"
        
        case .edit:
        titleLabel.text = "Edit Comment"
        
        case .addList:
        titleLabel.text = "Add list"
        
        case .editList:
            titleLabel.text = "Edit list"
            
        default:
            titleLabel.text = ""
        }
//        popUpView.isHidden = false
//        popUpView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 12).isActive = true
//        popUpView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        
//        popUpView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
//        popUpView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        
        
        self.popUp()
    }
    
    func popUp()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
        });
    }
    
    func dissmiss()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
            
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }
    
    @IBAction func sentComment(_ sender: Any) {
        let path = row
        let text = commentView.text
        if self.type == .addList {
            if text?.count ?? 0 > 20 || text?.count ?? 0 <= 0{
                let alert = UIAlertController(title: "Playlist name length must smaller than 20 and more than 0", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                    self.dismiss(animated: true, completion: nil)
                    return
                }
            }
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        if text?.count ?? 0 > 0 {
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.userInfo = UserInfo(dictionary: dictionary)
                    self.userInfo?.id = uid
                    self.handleUpdate(path: path, text: text)
                    return
                }
            }, withCancel: nil)
        }
        
    }
    
    func handleUpdate(path: Int, text: String?) {
    
    switch self.type {
    case .edit:
        if let textCotent = text{
            ref.child("music").child(mid).child("comments").child(cid).child("comment_text").setValue(textCotent)
        }
        self.dismiss(animated: true, completion: nil)
    case .add:
        guard let text = commentView.text else { return  }
        if let user = userInfo {
            addComment(mid: self.mid, userInfo: user, text: text, onSucess: { (comments) in
            }) { (errorMessage) in
                print(errorMessage ?? "Error Ouccur!")
            }
        }
        self.dismiss(animated: true, completion: nil)
        
    case .addList:
        if let user = userInfo, let textCotent = text {
            self.delegate?.postPlayingList(userInfo: user, text: textCotent)
        }

        self.dismiss(animated: true, completion: nil)
        
    case .editList:
        if pid != "" {
            if let textCotent = text, let uid = Auth.auth().currentUser?.uid {
                ref.child("playlist").child(uid).child(pid).child("name").setValue(textCotent)
            }
        }
        self.dismiss(animated: true, completion: nil)
        
    default:
       self.dismiss(animated: true, completion: nil)
    }
    }
    
    @IBAction func returnClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func `return`(_ sender: Any) {
        self.view.endEditing(true)
    }
}

extension PopUpViewController {
    func textViewDidChange(_ textView: UITextView) {
        //        if commentTextView.text.count <= 0 {
        //            self.sendButton.isEnabled = false
        //        }
        print(commentView.text ?? "")
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        var newText = textView.text!
        newText.removeAll { (character) -> Bool in
            return character == " " || character == "\n"
        }
        return (newText.count + text.count) <= 100
    }
    
    
    
}

