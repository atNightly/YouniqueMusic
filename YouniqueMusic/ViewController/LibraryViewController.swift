//
//  LibraryViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase

class LibraryViewController: UIViewController, PopViewDelegate {
    
    @IBOutlet var historyView: UIStackView!
    @IBOutlet var favouriteView: UIStackView!
    @IBOutlet var playListTableView: UITableView!
    var delegate: MusicControlDelegate?
    let ref = Database.database().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var playlists: Playlists = Playlists()
    var favouriteList: PlaylistInfo?
    var historyList: PlaylistInfo?
    
    deinit {
        print("LibraryViewController")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setNav()
        loadPlaylist()
        
        playListTableView.dataSource = self
        playListTableView.delegate = self
        playListTableView.rowHeight = 80
        playListTableView.backgroundColor = .clear
//        historyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toHistoryListView)))
        favouriteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toFavouriteListView)))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playListTableView.reloadData()
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toMusicView)))
//            if appDelegate.playerItem != nil {
//                view.isHidden = false
//            } else {
//                view.isHidden = true
//                return
//            }
        }
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //  self.navigationController?.tabBarController?.tabBar.isHidden = true
        
    }

    
    func setNav() {
        let image = UIImage(named:"Add to Playlist")!.withRenderingMode(.alwaysTemplate)
        
        let item = UIBarButtonItem(image: image,style: UIBarButtonItem.Style.plain,target:self,action:#selector(addnNewList))
        
        self.navigationItem.rightBarButtonItem = item
        self.navigationItem.rightBarButtonItem?.tintColor = .gray
        
        self.navigationController?.tabBarController?.tabBar.barTintColor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
    }
    
    func loadPlaylist() {
        playlists.removeAll()
        
        guard let currentID = Auth.auth().currentUser?.uid else { return }
        ref.child("playlist").child(currentID).observe(.childAdded, with: {
            snapshot in
            self.ref.child("playlist").child(currentID).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                let key = snap.key
                
                if var dict = snap.value as? [String: AnyObject] {
                    let playlist = PlaylistInfo(key: snap.key, dict: dict)
                    if key == "favourite" {
                        self.favouriteList = playlist
                    } else if key == "history" {
                        self.historyList = playlist
                    } else {
                        self.playlists.append(playlist: playlist)
                        self.playListTableView.reloadData()
                    }
                }
            })
        })
        
        ref.child("playlist").child(currentID).observe(.childChanged, with: {
            snapshot in
            self.ref.child("playlist").child(currentID).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                if let dict = snap.value as? [String: AnyObject] {
                    let playlist = PlaylistInfo(key: snap.key, dict: dict)
                    self.playlists.update(playlistItem: playlist)
                        self.playListTableView.reloadData()
                }
            })
        })
        
        ref.child("playlist").child(currentID).observe(.childRemoved, with: {
            snapshot in
            self.ref.child("playlist").child(currentID).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                self.playlists.remove(key: snap.key)
                self.playListTableView.reloadData()
            })
        })
    }
    
    
    
    @objc func toFavouriteListView() {
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.playlist = PlaylistDetail(playlist: self.favouriteList)
        controller.type = .favourite
        controller.navTitle = "Favourite"
        self.navigationController?.pushViewController(controller, animated: true)
    }
    @objc func toHistoryListView() {
       let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.playlist = PlaylistDetail(playlist: self.historyList)
        controller.type = .history
        controller.navTitle = "History"
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func toMusicView() {
        if self.delegate != nil {
            delegate?.toMusicDetailView(controller: self)
        }
    }
    
    @objc func addnNewList() {
        let popVC = UIStoryboard(name: "Basic", bundle: nil).instantiateViewController(withIdentifier: "popID") as! PopUpViewController
        popVC.delegate = self as PopViewDelegate
        popVC.type = .addList
        self.present(popVC, animated: true)
    }
    
    func setPlayListCell(cell: PlayListCell, indexPath: IndexPath) {
        cell.moreInfoImage.tag = indexPath.row
        cell.moreInfoImage.isUserInteractionEnabled = true
        cell.moreInfoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleEdit(tapGestureRecognizer:))))
        let playlistInfo = self.playlists.playistLists[indexPath.row]
        cell.songNameLabel.text = playlistInfo.name
        if let tmsp = playlistInfo.timestamp {
            if let time = Int(tmsp) {
                let date = Date(timeIntervalSince1970: TimeInterval(time))
                let dformatter = DateFormatter()
                dformatter.dateFormat = "yyyy-MM-dd"
                cell.artistLabel.text  = "Create Date: " + dformatter.string(from: date)
            } else {
                cell.artistLabel.text = ""
            }
        }
        
        if self.playlists.playistLists.count > 0 {
            if let url = playlists.playistLists[indexPath.row].profileURL {
                cell.idString = url
                cell.downloadImageUsingCacheWithLink(url, view:playListTableView)
            }
            else {
                if let url = playlists.playistLists[indexPath.row].tracks?[0].al?.picUrl {
                    cell.idString = url
                    cell.downloadImageUsingCacheWithLink(url, view:playListTableView)
                }
            }
        }

    }
    
    @objc func handleEdit(tapGestureRecognizer: UITapGestureRecognizer) {
        let image = tapGestureRecognizer.view as! UIImageView
        let row = image.tag
        let popVC = UIStoryboard(name: "Basic", bundle: nil).instantiateViewController(withIdentifier: "popID") as! PopUpViewController
        popVC.type = .editList
        popVC.pid = playlists.playistLists[row].id ?? ""
        self.present(popVC, animated: true)
    }
    
    
    func postPlayingList(userInfo: UserInfo, text: String) {
        let alert = UIAlertController(title: "Updating playlist......", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
        guard let id = Auth.auth().currentUser?.uid else {return}
        
        addNewPlaylist(uid: id, userInfo: userInfo, text: text, onSucess: { (playlist) in
        }) { (errorMessage) in
            print(errorMessage ?? "Error Ouccur!")
            let alert = UIAlertController(title: "Error Ouccur!", message: errorMessage, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func addNewPlaylist(uid: String, userInfo: UserInfo, text: String, onSucess: @escaping ([PlaylistInfo]) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        let ref = Database.database().reference()
        ref.child("playlist").child(uid).runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            let count = currentData.childrenCount
            var newId: String
            newId = ref.child("playlist").child(uid).childByAutoId().key ?? String(count)
            let newPlaylistRef = ref.child("playlist").child(uid).child(newId)
            if let uid = userInfo.id {
                let timeInterval:TimeInterval = Date().timeIntervalSince1970
                let timeStamp = Int(timeInterval)
                let info = ["uid": uid, "id": newId, "profile_url": "", "timestamp": String(timeStamp), "name": text, "tracks": []] as [String : Any]
                newPlaylistRef.setValue(info)
            }
            
            return TransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                onError(error.localizedDescription)
                let updateAlert = UIAlertController(title: "uploding info...",
                                                    message: nil, preferredStyle: .alert)
            }
        }
    }
}

extension LibraryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.playistLists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistcellid", for: indexPath) as! PlayListCell
        setPlayListCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.pid = playlists.playistLists[indexPath.row].id
        self.navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let pid = self.playlists.playistLists[indexPath.row].id {
            self.ref.child("playlist").child(uid).child(pid).removeValue()
            self.playlists.remove(key: pid)
            let indexPaths = [indexPath]
            tableView.deleteRows(at: indexPaths, with: .fade)
        }
        

    }
}


