//
//  SearchViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController, SearchDelegate, UISearchBarDelegate {
    
    @IBOutlet var searchHistoryTableView: UITableView!
    
    @IBOutlet var searchBar: UISearchBar!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var delegate: MusicControlDelegate?
    let ref = Database.database().reference()
    var songsInfo : [SongInfo] = []
    var searchList: [SearchHistory] = []
    var removeIndex: Int?
    
    var playlist: PlaylistDetail?
    var songIndex = 0
    var trackInfo: SongInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNav()
        
        searchHistoryTableView.dataSource = self
        searchHistoryTableView.delegate = self
        searchHistoryTableView.rowHeight = 80
        searchHistoryTableView.backgroundColor = .clear
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.textColor = .white
        searchBar.delegate = self

        
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toMusicView)))
        }
        
        loadSearchList()
        // Do any additional setup after loading the view.
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toMusicView)))
        }
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.songsInfo = []
        self.view.endEditing(true)
        // self.navigationController?.tabBarController?.tabBar.isHidden = true
        
    }
    
    
    func setNav() {
        let image = UIImage(systemName:"person.circle")!.withRenderingMode(.alwaysTemplate)
        
        let item = UIBarButtonItem(image: image,style: UIBarButtonItem.Style.plain,target:self,action:#selector(jumpToProfile))
        
        self.navigationItem.rightBarButtonItem = item
        self.navigationItem.rightBarButtonItem?.tintColor = .gray
        
        self.navigationController?.tabBarController?.tabBar.barTintColor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
    }
    
    func loadSearchList() {
        searchList = []
        self.searchHistoryTableView.reloadData()
        guard let currentID = Auth.auth().currentUser?.uid else { return }
        ref.child("search").child(currentID).observe(.childAdded, with: {
            snapshot in
            self.ref.child("search").child(currentID).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                if var dict = snap.value as? [String: AnyObject] {
                    if let e = dict["track"] as? [String: AnyObject] {
                        var al: Album?
                        var artistArray: [Artist] = []
                        let name = e["name"] as? String
                        let id = e["id"] as? Int
                        let liked = e["liked"] as? Bool
                        if let ars = e["artist"] as? [String: AnyObject] {
                            for item in ars {
                                let a = Artist(id: item.value["id"] as? Int, name: item.value["name"] as? String)
                                artistArray.append(a)
                            }
                        }
                        
                        if let album = e["album"] as? [String: AnyObject] {
                            let id = album["id"] as? Int
                            let name = album["name"] as? String
                            let picUrl = album["picUrl"] as? String
                            let pic = album["pic"] as? Int
                            let pic_str = album["pic_str"] as? String
                            al = Album(id: id, name: name, picUrl: picUrl, pic_str: pic_str, pic: pic)
                        }
                        let sItem = SongInfo(name: name, id: id, ar: artistArray, al: al, liked: liked, timestamp: nil)
                        dict["track"] = sItem as AnyObject
                    }
                    let search = SearchHistory(dict: dict)
                    self.searchList.append(search)
                    self.searchHistoryTableView.reloadData()
                }
            })
        })
        
        ref.child("search").child(currentID).observe(.childRemoved, with: {
            snapshot in
            self.ref.child("search").child(currentID).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                var list: [SearchHistory] = []
                for item in self.searchList {
                    if  item.sid !=  snap.key{
                        list.append(item)
                    }
                }
                self.searchList = list
                self.searchHistoryTableView.reloadData()
            })
        })
        
    }
    
    @objc func toMusicView() {
        if self.delegate != nil {
            delegate?.toMusicDetailView(controller: self)
        }
    }
    
    @objc func jumpToProfile() {
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "profileID") as ProfileViewController
        if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.isHidden = true
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }
    @IBAction func searchButton(_ sender: Any) {
        let alert = UIAlertController(title: "Loading", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            return
        }
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.needSegment = true
        //guard let searchKey = searchBar.text else {return}
        //let key = searchKey.replacingOccurrences(of: " ", with: "%20")
        if let key = searchBar.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            appDelegate.apiManager.downloadSearchJSON(url: SONG_SEARCH_URL + key + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                if let songlist = data?.songList {
                    for item in songlist {
                        let album = Album(id: item.album?.id, name: item.album?.name, picUrl: item.album?.cover, pic_str: "", pic: -1)
                        let songInfo = SongInfo(name: item.name, id: item.id, ar: item.artists ?? [], al: album, liked: false, timestamp: nil)
                        self.songsInfo.append(songInfo)
                    }
                    let p = PlaylistDetail(dict: [:], tracks: self.songsInfo)
                    controller.customerPlaylist = p
                    controller.isCustomList = true
                    controller.searchKey = key
                    controller.searchDelegate =  self
                }
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
    }
    
    
    @IBAction func clearAllHistory(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.ref.child("search").child(uid).removeValue()
    }
    
    
    func setSearchHostory(type: SearchType?, id: String?, picUrl: String?, timestamp: String?, name: String?, track: [String: Any]) {
        var t = ""
        switch type {
        case .artist:
            t = "artist"
        default:
            t = "song"
        }
        var dict = ["type": t, "id": id, "picURL": picUrl, "timestamp": timestamp, "name": name, "track": track] as [String : AnyObject]
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let newId = ref.child("search").child(uid).childByAutoId().key ?? randomString(length: 10)
        dict["sid"] = newId as AnyObject
        self.ref.child("search").child(uid).child(newId).setValue(dict)
    }
    
    @objc func handleDeleteButton(tapGestureRecognizer: UITapGestureRecognizer) {
        let image = tapGestureRecognizer.view as! UIImageView
        let row = image.tag
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if let sid = self.searchList[row].sid{
            self.ref.child("search").child(uid).child(sid).removeValue()
            self.removeIndex = row
        }
    }
    
    func setCell(cell:PlayListCell, indexPath: IndexPath) {
        cell.tag = indexPath.row
        cell.moreInfoImage.tag = indexPath.row
        cell.moreInfoImage.isUserInteractionEnabled = true
        cell.moreInfoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDeleteButton(tapGestureRecognizer:))))
        
        if searchList[indexPath.row].type == "artist" {
            cell.trackImage.layer.cornerRadius = 35
            cell.artistLabel.text = "artist"
        } else {
            cell.trackImage.layer.cornerRadius = 0
            cell.artistLabel.text = "song"
        }
        if let url = searchList[indexPath.row].picUrl{
            let Url = url
            cell.idString = Url
            cell.downloadImageUsingCacheWithLink(Url, view: self.searchHistoryTableView)
        }
        cell.songNameLabel.text = searchList[indexPath.row].name
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistcellid", for: indexPath) as! PlayListCell
        cell.isUserInteractionEnabled = true
        setCell(cell:cell, indexPath: indexPath)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? PlayListCell
        guard let id = searchList[indexPath.row].id else {
            let alert = UIAlertController(title: "No info!", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
            return
        }
        if searchList[indexPath.row].type == "artist" {
            let storyboard = UIStoryboard(name: "Library", bundle: nil)
            let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
            appDelegate.apiManager.downloadArtistTracksJSON(url: ARTIST_SONGS_URL + "\(id)" + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                let songsInfo = data
                let p = PlaylistDetail(dict: [:], tracks: songsInfo)
                let playlist = p
                controller.customerPlaylist = playlist
                controller.isCustomList = true
                self.navigationController?.pushViewController(controller, animated: true)
                
                return
            }
        } else if searchList[indexPath.row].type == "song" {
            let track = [searchList[indexPath.row].track]
            let playlist = PlaylistDetail(dict: [:], tracks: track as? [SongInfo])
            self.delegate?.toMusicDetailView(playlist: playlist, songIndex: 0, tracks: track as! [SongInfo], trackInfo: searchList[indexPath.row].track)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar:UISearchBar) {
        let alert = UIAlertController(title: "Loading", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            return
        }
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.needSegment = true
        //guard let searchKey = searchBar.text else {return}
        //let key = searchKey.replacingOccurrences(of: " ", with: "%20")
        if let key = searchBar.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            appDelegate.apiManager.downloadSearchJSON(url: SONG_SEARCH_URL + key + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                if let songlist = data?.songList {
                    for item in songlist {
                        let album = Album(id: item.album?.id, name: item.album?.name, picUrl: item.album?.cover, pic_str: "", pic: -1)
                        let songInfo = SongInfo(name: item.name, id: item.id, ar: item.artists ?? [], al: album, liked: false, timestamp: nil)
                        self.songsInfo.append(songInfo)
                    }
                    let p = PlaylistDetail(dict: [:], tracks: self.songsInfo)
                    controller.customerPlaylist = p
                    controller.isCustomList = true
                    controller.searchKey = key
                    controller.searchDelegate =  self
                }
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
        
    }
    
}

func verticalPushAnimated(Controller: UINavigationController) {
    
    let animation = CATransition.init()
    animation.duration = 0.25
    animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    animation.type = CATransitionType.moveIn
    animation.subtype = CATransitionSubtype.fromTop
    Controller.view.layer.add(animation, forKey: nil)
}


func verticalPopAnimated(Controller: UINavigationController) {
    
    let animation = CATransition.init()
    animation.duration = 0.25
    animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    animation.type = CATransitionType.reveal
    animation.subtype = CATransitionSubtype.fromBottom
    Controller.view.layer.add(animation, forKey: nil)
}

func verticalPresentAnimated(Controller: UITabBarController) {
    
    let animation = CATransition.init()
    animation.duration = 0.25
    animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    animation.type = CATransitionType.moveIn
    animation.subtype = CATransitionSubtype.fromTop
    Controller.view.layer.add(animation, forKey: nil)
}


func verticalDismissAnimated(Controller: UITabBarController) {
    
    let animation = CATransition.init()
    animation.duration = 0.25
    animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.linear)
    animation.type = CATransitionType.reveal
    animation.subtype = CATransitionSubtype.fromBottom
    Controller.view.layer.add(animation, forKey: nil)
}
