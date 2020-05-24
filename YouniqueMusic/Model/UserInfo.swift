//
//  UserInfo.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import Foundation
import Firebase

class UserInfo: NSObject {
    var id: String?
    var username: String?
    var email: String?
    var birthday: String?
    var gender: String?
    var profileurl: String?
    
    init(dictionary: [String: AnyObject]) {
        self.id = dictionary["id"] as? String
        self.username = dictionary["username"] as? String
        self.email = dictionary["email"] as? String
        self.birthday = dictionary["birthday"] as? String
        self.gender = dictionary["gender"] as? String
        self.profileurl = dictionary["profileurl"] as? String
    }
}


class Comment {
    var uid: String?
    var id: String?
    var likeCount: Int?
    var likes: Dictionary<String, Any>?
    var isLiked: Bool?
    var profileURL: String?
    var commentText: String?
    var username: String?
    var isSelfPost: Bool = false
    var timestamp: String?
    
    
    init(key: String, dict: [String:Any]) {
        id = key
        uid = dict["uid"] as? String
        likeCount = dict["like_count"] as? Int
        likes = dict["likes"] as? Dictionary<String, Any>
        profileURL = dict["profile_url"] as? String
        commentText = dict["comment_text"] as? String
        timestamp = dict["timestamp"] as? String
        if uid != nil {
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.username = dictionary["username"] as? String
                }
                
            }, withCancel: nil)
        } else {
            self.username = ""
        }
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            isSelfPost = uid == currentUserId
            
            guard let likesDic = likes else{
                isLiked = false
                return
            }
            isLiked = likesDic[currentUserId] != nil
        }
    }
}
