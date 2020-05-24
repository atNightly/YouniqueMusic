//
//  PlayListDetailViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase

enum listType {
    case favourite
    case history
    case none
}
protocol MusicDetailControlDelegate: NSObjectProtocol {
    func refreshPlayingSong(playlist: PlaylistDetail?, index: Int)
    func refreshPlayingList(playlist: PlaylistDetail?)
}

protocol SearchDelegate: NSObjectProtocol {
    func setSearchHostory(type: SearchType?, id: String?, picUrl: String?, timestamp: String?, name: String?, track: [String: Any])
}


class PlayListDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var playListTableView: UITableView!
    @IBOutlet var searchSegment: UISegmentedControl!
    var playlist: PlaylistDetail?
    var customerPlaylist: PlaylistDetail?
    var tracks: [SongInfo]?
    var navTitle: String = "playing list"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var needSegment = false
    var type = listType.none
    let ref = Database.database().reference()
    var pid: String?
    var removeIndex: Int?
    var isCustomList = false
    var searchKey: String?
    var isArtist = false
    var fromMusic = false
    var artists: [SearchListArtistInfo]?
    var delegate: MusicDetailControlDelegate?
    var searchDelegate: SearchDelegate?
    
    var musicDelegate: MusicControlDelegate = UIApplication.shared.delegate?.window??.rootViewController as! MusicControlDelegate
    
    deinit {
        print("deinit PlayListDetailViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
        playListTableView.delegate = self
        playListTableView.dataSource = self
        playListTableView.rowHeight = 80
        if !needSegment {
            searchSegment.isHidden = true
        }
        if pid == nil {
            pid = playlist?.pid
        }
        setUI()
        loadList()
        searchSegment.addTarget(
            self,
            action:
            #selector(switchArtist),
            for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playListTableView.reloadData()
        if fromMusic {
            if let views = self.appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
                let view = views[0] as! MusicView
                
                view.isHidden = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if !fromMusic {
            if let views = self.appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
                let view = views[0] as! MusicView
                view.isHidden = false
            }
        }
    }
    
    func setUI() {
        switch type {
        case .favourite:
            navTitle = "Favourite Songs"
            self.pid = "favourite"
            self.navigationItem.title = navTitle
        case .history:
            navTitle = "Histroy"
            self.pid = "history"
            self.navigationItem.title = navTitle
        default:
            self.navigationItem.title = navTitle
        }
        
        let dic:NSDictionary = [NSAttributedString.Key.foregroundColor:UIColor.white,NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 20)];
        searchSegment.setTitleTextAttributes(dic as! [NSAttributedString.Key : Any] , for: UIControl.State.normal)
        
    }
    
    @objc func switchArtist(sender: UISegmentedControl) {
        playlist = nil
        let alert = UIAlertController(title: "Loading...", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        if sender.selectedSegmentIndex == 1 {
            
            guard let key = self.searchKey else {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
            appDelegate.apiManager.downloadSearchArtistJSON(url: SEARCH_URL + key + "?type=ARTIST" + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                self.artists = data?.result?.artists
                self.isArtist = true
                
                self.playListTableView.reloadData()
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                if self.playListTableView.numberOfRows(inSection: 0) > 0 {
                    self.scrollToFirstRow()
                }
            }
        } else {
            guard let key = self.searchKey else {return}
            
            appDelegate.apiManager.downloadSearchJSON(url: SONG_SEARCH_URL + key + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                var songsInfo: [SongInfo] = []
                if let songlist = data?.songList {
                    for item in songlist {
                        let album = Album(id: item.album?.id, name: item.album?.name, picUrl: item.album?.cover, pic_str: "", pic: -1)
                        
                        let songInfo = SongInfo(name: item.name, id: item.id, ar: item.artists ?? [], al: album, liked: false, timestamp: nil)
                        songsInfo.append(songInfo)
                    }
                    let p = PlaylistDetail(dict: [:], tracks: songsInfo)
                    self.playlist = p
                    self.isArtist = false
                    self.playListTableView.reloadData()
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                    if self.playListTableView.numberOfRows(inSection: 0) > 0 {
                        self.scrollToFirstRow()
                    }
                }
            }
        }
    }
    
    func loadList() {
        if customerPlaylist != nil {
            self.playlist = customerPlaylist
            self.tracks = self.playlist?.tracks
            self.playListTableView.reloadData()
            return
        }
        guard let currentID = Auth.auth().currentUser?.uid else { return }
        guard let pid = self.pid else {return }
        
        ref.child("playlist").child(currentID).child(pid).observe(.childAdded, with: {
            snapshot in
            var tracks : [SongInfo] = []
            var dictionary: [String: AnyObject] = [:]
            self.ref.child("playlist").child(currentID).child(pid).child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                if snap.key != "tracks" {
                    dictionary[snapshot.key] = snap.value as AnyObject?
                } else if let dict = snap.value as? [String: AnyObject] {
                    for e in dict {
                        var al: Album?
                        var artistArray: [Artist] = []
                        let name = e.value["name"] as? String
                        let timestamp = e.value["timestamp"]
                        let id = e.value["id"] as? Int
                        let liked = e.value["liked"] as? Bool
                        if let ars = e.value["artist"] as? [String: AnyObject] {
                            for item in ars {
                                let a = Artist(id: item.value["id"] as? Int, name: item.value["name"] as? String)
                                artistArray.append(a)
                            }
                        }
                        
                        if let album = e.value["album"] as? [String: AnyObject] {
                            let id = album["id"] as? Int
                            let name = album["name"] as? String
                            let picUrl = album["picUrl"] as? String
                            let pic = album["pic"] as? Int
                            let pic_str = album["pic_str"] as? String
                            al = Album(id: id, name: name, picUrl: picUrl, pic_str: pic_str, pic: pic)
                        }
                        let sItem = SongInfo(name: name, id: id, ar: artistArray, al: al, liked: liked, timestamp: timestamp as? String)
                        tracks.append(sItem)
                    }
                    let dict = ["id": pid, "name": "", "coverImgUrl": "", "pic": -1, "pic_str": "-1"] as [String: AnyObject]
                    tracks.sort(by: {(a, b) in
                        if (a.timestamp?.caseInsensitiveCompare((b.timestamp ?? "0") as String).rawValue ?? 0) as Int == -1 {
                            return true
                        }
                        return false
                    }
                    )
                    self.playlist = PlaylistDetail(dict: dict, tracks: tracks)
                    self.tracks = self.playlist?.tracks
                    self.playListTableView.reloadData()
                }
                
            })
            
        })
        
        ref.child("playlist").child(currentID).child(pid).child("tracks").observe(.childRemoved, with: {
            snapshot in
            self.ref.child("playlist").child(currentID).child(pid).child("tracks").child(snapshot.key).observeSingleEvent(of: .value, with: { (snap) in
                if let index = self.removeIndex {
                    self.playlist?.tracks?.remove(at: index)
                    self.tracks = self.playlist?.tracks
                    self.playListTableView.reloadData()
                }
                
            })
        })
    }
    
    func setCell(cell: PlayListCell, index: IndexPath) {
        cell.tag = index.row
        cell.moreInfoImage.tag = index.row
        
        if !isCustomList && self.playlist?.tracks?.count ?? 0 > 1 {
            cell.moreInfoImage.isUserInteractionEnabled = true
            cell.moreInfoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDeleteButton(tapGestureRecognizer:))))
        } else if !isCustomList && self.playlist?.tracks?.count ?? 0 == 1 {
            if !fromMusic {
                cell.moreInfoImage.isUserInteractionEnabled = true
                cell.moreInfoImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDeleteButton(tapGestureRecognizer:))))
            } else {
                    cell.moreInfoImage.isHidden = true
            }
        } else {
                cell.moreInfoImage.isHidden = true
        }
        
        if isArtist {
            cell.trackImage.layer.cornerRadius = 35
            cell.songNameLabel.text = artists?[index.row].name
            cell.artistLabel.isHidden = true
            if let url = artists?[index.row].img1v1Url{
                let Url = url + IMAGE_PARA
                cell.idString = Url
                cell.downloadImageUsingCacheWithLink(Url, view: playListTableView)
            }
        } else {
            cell.trackImage.layer.cornerRadius = 0
            cell.songNameLabel.text = tracks?[index.row].name
            var artistName = ""
            if let artist = tracks?[index.row].ar {
                for item in artist {
                    artistName += (item.name ?? "" + " ")
                }
            }
            cell.artistLabel.text = artistName
            if let url = tracks?[index.row].al?.picUrl{
                let Url = url + IMAGE_PARA
                cell.idString = Url
                cell.downloadImageUsingCacheWithLink(Url, view: playListTableView)
            }
        }
    }
    
    @objc func handleDeleteButton(tapGestureRecognizer: UITapGestureRecognizer) {
        let image = tapGestureRecognizer.view as! UIImageView
        let row = image.tag
        if isCustomList || fromMusic {
            if self.playlist?.tracks?[row].id == appDelegate.playingID {
                self.playlist?.tracks?.remove(at: row)
                self.tracks = self.playlist?.tracks
                self.delegate?.refreshPlayingSong(playlist: self.playlist, index: row)
                self.playListTableView.reloadData()
                return
            }
            self.playlist?.tracks?.remove(at: row)
            delegate?.refreshPlayingList(playlist: self.playlist)
            self.tracks = self.playlist?.tracks
            self.playListTableView.reloadData()
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {return}
        if let mid = self.playlist?.tracks?[row].id, let pid = playlist?.pid {
            self.ref.child("playlist").child(uid).child(pid).child("tracks").child(String(mid)).removeValue()
            self.removeIndex = row
        }
    }
    
    func setTrack(songIndex: Int, indexPath: IndexPath) {
        let track = self.playlist?.tracks?[songIndex]
        let name = track?.name
        let id = track?.id
        
        var alDict = [:] as [String: Any]
        var arDict = [:] as [String: Any]
        if let al = track?.al {
            alDict = ["id": al.id, "name": al.name, "pic": al.pic, "picUrl": al.picUrl, "pic_str": al.pic_str]
        }
        if let ars = track?.ar {
            for ad in ars {
                let dict = ["id": ad.id, "name":ad.name] as [String: Any]
                if let id = ad.id {
                    arDict[String(id)] = dict
                }
            }
        }
        let values = ["id": id, "artist": arDict, "name": name, "album": alDict] as [String: Any]
        
        let cell = self.playListTableView.cellForRow(at: indexPath) as? PlayListCell
        let timeInterval:TimeInterval = Date().timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        if let id = self.playlist?.tracks?[indexPath.row].id {
           self.searchDelegate?.setSearchHostory(type: .song, id: String(id), picUrl: cell?.idString, timestamp: String(timeStamp), name: cell?.songNameLabel.text, track: values)
        }
        
    }
    
    //    func loadArtistTracks(id: String) {
    //        appDelegate.apiManager.downloadSearchJSON(url: SONG_SEARCH_URL + id + LIMIT_INDEX){ (data, error) in
    //            if let error = error {
    //                print("No data asvailable \(error.localizedDescription)")
    //                return
    //            }
    //            var songsInfo : [SongInfo] = []
    //            if let songlist = data?.hotSongs {
    //                for item in songlist {
    //                    let album = Album(id: item.album?.id, name: item.album?.name, picUrl: item.album?.cover, pic_str: "", pic: -1)
    //                    let songInfo = SongInfo(name: item.name, id: item.id, ar: item.artists ?? [], al: album, liked: false)
    //                    songsInfo.append(songInfo)
    //                }
    //                let p = PlaylistDetail(dict: [:], tracks: songsInfo)
    //                self.playlist = p
    //            }
    //        }
    //    }
}

extension PlayListDetailViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isArtist {
            return self.artists?.count ?? 0
        } else if let tracks = playlist?.tracks {
            return tracks.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistcellid", for: indexPath) as! PlayListCell
        self.setCell(cell: cell, index: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isArtist {
            let storyboard = UIStoryboard(name: "Library", bundle: nil)
            let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
            guard let id = self.artists?[indexPath.row].id else { return }
            appDelegate.apiManager.downloadArtistTracksJSON(url: ARTIST_SONGS_URL + "\(id)" + LIMIT_INDEX){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                let songsInfo = data
                let p = PlaylistDetail(dict: [:], tracks: songsInfo)
                self.playlist = p
                controller.customerPlaylist = self.playlist
                controller.isCustomList = true
                let cell = self.playListTableView.cellForRow(at: indexPath) as? PlayListCell
                let timeInterval:TimeInterval = Date().timeIntervalSince1970
                let timeStamp = Int(timeInterval)
                self.searchDelegate?.setSearchHostory(type: .artist, id: "\(id)", picUrl: cell?.idString, timestamp: String(timeStamp), name: cell?.songNameLabel.text, track: [:])
                self.navigationController?.pushViewController(controller, animated: true)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
        }  else {
            if fromMusic {
                self.delegate?.refreshPlayingSong(playlist: self.playlist, index: indexPath.row)
                self.navigationController?.popViewController(animated: true)
                return
            }
            self.musicDelegate.toMusicDetailView(playlist: self.playlist, songIndex: indexPath.row, tracks: tracks, trackInfo: self.playlist?.tracks?[indexPath.row])
            if !searchSegment.isHidden {
                setTrack(songIndex: indexPath.row, indexPath: indexPath)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func scrollToFirstRow() {
        let indexPath = IndexPath(row: 0, section: 0)
        self.playListTableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}


