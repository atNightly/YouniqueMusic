//
//  CommentViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import NotificationCenter
import Firebase



class CommentViewController: UIViewController {
    @IBOutlet var commentCountLabel: UILabel!
    @IBOutlet var trackImage: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var commentTableView: UITableView!
    @IBOutlet var addCommentButton: UIButton!
    
    let ref = Database.database().reference()
    var comments: CommentList = CommentList()
    var users: [UserInfo] = []
    var musicID = ""
    var trackInfo: SongInfo?
    
    deinit {
        print("CommentViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.estimatedRowHeight = 200
        commentTableView.rowHeight = UITableView.automaticDimension
        
        songNameLabel.numberOfLines = 2
        songNameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        addCommentButton.addTarget(self, action: #selector(handleAddComment), for: UIControl.Event.touchUpInside)
        loadComments()
        songNameLabel.text = trackInfo?.name
        artistLabel.text = trackInfo?.ar?[0].name
        if let url = trackInfo?.al?.picUrl {
            guard let URL = URL(string: url) else {return}
            trackImage.downloadedFrom(url: URL)
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            
            view.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            
            view.isHidden = false
        }
    }
    
    func loadComments() {
        let mid = self.musicID
        
        ref.child("music").child(mid).child("comments").observe(.childAdded, with: {
            snapshot in
            self.ref.child("music").child(mid).child("comments").child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                print(snap.key)
                if let dict = snap.value as? [String: AnyObject] {
                    
                    if let uid = dict["uid"] {
                        self.fetchUser(uid: uid as! String, completed: {
                            let comment = Comment(key: snap.key, dict: dict)
                            self.comments.append(comment: comment)
                            self.commentCountLabel.text = "(\(self.comments.commentList.count))"
                            self.commentTableView.reloadData()
                            
                        })
                    }
                }
            })
        })
        
        ref.child("music").child(mid).child("comments").observe(.childRemoved, with: {
            snapshot in
            self.ref.child("music").child(mid).child("comments").child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                let userIndex = self.comments.remove(key: snap.key)
                if(userIndex >= 0){
                    self.users.remove(at: userIndex)
                }
                self.commentTableView.reloadData()
            })
        })
        
        ref.child("music").child(mid).child("comments").observe(.childChanged, with: {
            snapshot in
            self.ref.child("music").child(mid).child("comments").child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                if let dict = snap.value as? [String: AnyObject]{
                    let comment = Comment(key: snap.key, dict: dict)
                    self.comments.update(commentItem: comment)
                }
                self.commentTableView.reloadData()
            })
        })
    }
    
    func fetchUser(uid: String, completed:  @escaping () -> Void ) {
        
        ref.child("users").observeSingleEvent(of: .value, with: {
            snapshot in
            if let dict = snapshot.value as? [String: AnyObject] {
                //dict["id"] = uid as AnyObject
                let user = UserInfo(dictionary: dict[uid] as! [String : AnyObject])
                self.users.append(user)
                completed()
            }
        })
        
    }
    
    func setCommentCell(cell: CommentTableViewCell, row: Int) {
        cell.commentLabel.numberOfLines = 0
        cell.commentLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.commentLabel.text = comments.commentList[row].commentText
        cell.likeImage.tag = row
        cell.deleteButton.tag = row
        cell.deleteButton.isHidden = !comments.commentList[row].isSelfPost
        cell.editButton.tag = row
        cell.editButton.isHidden = !comments.commentList[row].isSelfPost
        cell.likeImage.isHighlighted = comments.commentList[row].isLiked ?? false
        cell.likeImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLikeButton)))
        
        if !cell.deleteButton.isHidden {
            cell.deleteButton.addTarget(self, action: #selector(handleDeleteButton), for: UIControl.Event.touchUpInside)
        }
        if !cell.editButton.isHidden {
            cell.editButton.addTarget(self, action: #selector(handleEditButton), for: UIControl.Event.touchUpInside)
        }
        if let tmsp = self.comments.commentList[row].timestamp {
            if let time = Int(tmsp) {
                let date = Date(timeIntervalSince1970: TimeInterval(time))
                let dformatter = DateFormatter()
                dformatter.dateFormat = "yyyy-MM-dd"
                cell.timeLabel.text = dformatter.string(from: date)
            }
        }
        if let url =  users[row].profileurl {
            cell.idString = url
            downloadImageUsingCacheWithLink(url, cell: cell)
        }
        if let count = comments.commentList[row].likeCount {
            cell.countLabel.text = "\(count)"
        }
        if let username = users[row].username {
            cell.userNameLabel.text = username
        }
    }
    
    @objc func handleLikeButton(sender: UITapGestureRecognizer) {
        let view = sender.view as? UIImageView
        guard let row = view?.tag else { return }
        if let cid = self.comments.commentList[row].id, let uid = Auth.auth().currentUser?.uid {
            incrementLikes(uid: uid, cid: cid, mid: self.musicID, onSucess: { (comment) in
                self.commentTableView.reloadData()
            }) { (errorMessage) in
                print(errorMessage ?? "Error Ouccur!")
            }
        }
    }
    
    @objc func handleDeleteButton(button: UIButton) {
        let row = button.tag
        if let cid = self.comments.commentList[row].id {
            self.ref.child("music").child(self.musicID).child("comments").child(cid).removeValue()
        }
    }
    
    @objc func handleEditButton(button: UIButton) {
        let row = button.tag
        let indexPath = IndexPath(row: row, section: 3)
        let cell = self.commentTableView.cellForRow(at: indexPath) as? CommentTableViewCell
        let popVC = UIStoryboard(name: "Basic", bundle: nil).instantiateViewController(withIdentifier: "popID") as! PopUpViewController
        popVC.row = row
        popVC.type = .edit
        popVC.cid = comments.commentList[row].id ?? ""
        //popVC.comments = self.comments.commentList
        popVC.mid = self.musicID
        popVC.commentText = cell?.commentLabel.text
        self.present(popVC, animated: true)
    }
    
    @objc func handleAddComment(button: UIButton) {
        let popVC = UIStoryboard(name: "Basic", bundle: nil).instantiateViewController(withIdentifier: "popID") as! PopUpViewController
        popVC.type = .add
        popVC.comments = self.comments.commentList
        popVC.mid = self.musicID
        //setUserInfo(viewcontroller: popVC)
        self.present(popVC, animated: true)
    }
    
    
    func downloadImageUsingCacheWithLink(_ urlLink: String, cell: CommentTableViewCell) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let cachedImage = appDelegate.imageCache.object(forKey: urlLink as NSString) {
            if cell.idString == urlLink {
                cell.profileImage?.image = cachedImage
            }
            
            return
        }
        let url = URL(string: urlLink)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let err = error {
                cell.profileImage?.image = UIImage(systemName: "person.fill")
                print(err)
                return
            }
            DispatchQueue.main.async {
                if let newImage = UIImage(data: data!) {
                    appDelegate.imageCache.setObject(newImage, forKey: urlLink as NSString)
                    if cell.idString == urlLink {
                        cell.profileImage?.image = newImage
                        
                    }
                }
            }
        }).resume()
    }
    
    func incrementLikes(uid: String, cid: String, mid: String, onSucess: @escaping (Comment) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        ref.child("music").child(mid).child("comments").child(cid).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var comment = currentData.value as? [String : AnyObject]{
                var likes: Dictionary<String, Bool>
                likes = comment["likes"] as? [String : Bool] ?? [:]
                var likeCount = comment["like_count"] as? Int ?? 0
                if let _ = likes[uid] {
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                } else {
                    likeCount += 1
                    likes[uid] = true
                }
                comment["like_count"] = likeCount as AnyObject?
                comment["likes"] = likes as AnyObject?
                
                currentData.value = comment
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                onError(error.localizedDescription)
            }
            if let dict = snapshot?.value as? [String: Any] {
                let comment = Comment(key: snapshot!.key, dict: dict)
                onSucess(comment)
            }
        }
    }
    
    @IBAction func goBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension CommentViewController : UITableViewDataSource, UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentcellid", for: indexPath) as! CommentTableViewCell
        cell.selectionStyle = .none
        setCommentCell(cell: cell, row: indexPath.row)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 200
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.commentList.count
        
    }
}


func addComment(mid: String, userInfo: UserInfo, text: String, onSucess: @escaping ([Comment]) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
    let ref = Database.database().reference()
    ref.child("music").child(mid).child("comments").runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
        let comments = currentData.value as? [String : AnyObject]
        let count = comments?.count ?? 0
        var newCommentId: String
        newCommentId = ref.child("music").child(mid).child("comments").childByAutoId().key ?? (String(count))
        let newCommentRef = ref.child("music").child(mid).child("comments").child(newCommentId)
        if let uid = userInfo.id, let profileURL = userInfo.profileurl {
            let timeInterval:TimeInterval = Date().timeIntervalSince1970
            let timeStamp = Int(timeInterval)
            let info = ["uid": uid, "like_count": 0, "likes": [:], "cid": newCommentId, "profile_url": profileURL, "timestamp": String(timeStamp), "comment_text": text] as [String : Any]
            newCommentRef.setValue(info)
        }
        
        return TransactionResult.success(withValue: currentData)
        
    }) { (error, committed, snapshot) in
        if let error = error {
            onError(error.localizedDescription)
            let updateAlert = UIAlertController(title: "uploding info...",
                                                message: nil, preferredStyle: .alert)
        }
        var comments: [Comment] = []
        if let dict = snapshot?.value as? [String: Any] {
            for snap in dict {
                let comment = Comment(key: snap.key, dict: dict)
                comments.append(comment)
            }
            onSucess(comments)
        }
    }
}
