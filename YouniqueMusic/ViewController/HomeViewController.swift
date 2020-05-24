//
//  HomeViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit


protocol MusicControlDelegate: NSObjectProtocol
{
    func toMusicDetailView(controller: HomeViewController)
    func toMusicDetailView(controller: LibraryViewController)
    func toMusicDetailView(controller: SearchViewController)
//    func toMusicDetailView(controller: HomeViewController, secondVC: MusicPlayDetailViewController)
//    func toMusicDetailView(controller: LibraryViewController, secondVC: MusicPlayDetailViewController)
//    func toMusicDetailView(controller: SearchViewController, secondVC: MusicPlayDetailViewController)
    func setMusicView(controller: MusicPlayDetailViewController)
    func toMusicDetailView(playlist: PlaylistDetail?, songIndex: Int, tracks: [SongInfo]?, trackInfo: SongInfo?)
    
}

class HomeViewController: UIViewController {
    
    //    @IBOutlet var myScrollView: UIScrollView!
    @IBOutlet var PopularListView: UICollectionView!
    @IBOutlet var newReleaseView: UICollectionView!
    var newReleasePlaylist: PlaylistDetail?
    var popularPlaylist: PlaylistDetail?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var delegate: MusicControlDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNav()
        
        // myScrollView.contentSize = CGSizeMake(0, myScrollView.contentSize.height);
        newReleaseView.delegate = self
        newReleaseView.dataSource = self
        newReleaseView.alwaysBounceHorizontal = true
        PopularListView.delegate = self
        PopularListView.dataSource = self
        PopularListView.alwaysBounceHorizontal = true
        DispatchQueue.main.async {
            self.loadPlaylist()
        }
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if appDelegate.window?.rootViewController?.view.subviews.count ?? 0 > 0 {
            if let views = appDelegate.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
                let view = views[0] as! MusicView
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.toMusicView)))
//                if appDelegate.playerItem != nil {
//                    view.isHidden = false
//                } else {
//                    view.isHidden = true
//                    return
//                }
            }
        }
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.navigationController?.tabBarController?.tabBar.isHidden = true
        
    }
    
    func setNav() {
        let image = UIImage(systemName:"person.circle")!.withRenderingMode(.alwaysTemplate)
        
        let item = UIBarButtonItem(image: image,style: UIBarButtonItem.Style.plain,target:self,action:#selector(jumpToProfile))
        
        self.navigationItem.rightBarButtonItem = item
        self.navigationItem.rightBarButtonItem?.tintColor = .gray
        
        self.navigationController?.tabBarController?.tabBar.barTintColor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
    }
    
    
    
    
    @objc func toMusicView(sender: UITapGestureRecognizer) {
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
    
    @IBAction func viewAllNew(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.playlist = self.newReleasePlaylist
        controller.tracks = self.newReleasePlaylist?.tracks
        controller.navTitle = "New Release List"
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    @IBAction func viewAllPopular(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.playlist = self.popularPlaylist
        controller.tracks = self.popularPlaylist?.tracks
        controller.navTitle = "Popular Music List"
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func loadPlaylist() {
        appDelegate.apiManager.downloadPlayListJSON(url: "https://api.imjad.cn/cloudmusic/?type=playlist&id=2809577409"){ (data, error) in
            if let error = error {
                print("No data asvailable \(error.localizedDescription)")
                return
            }
            guard let playlist = data?.playlist else { return }
            self.newReleasePlaylist = playlist
            self.newReleaseView.reloadData()
        }
        
        appDelegate.apiManager.downloadPlayListJSON(url: "https://api.imjad.cn/cloudmusic/?type=playlist&id=60198"){ (data, error) in
            if let error = error {
                print("No data asvailable \(error.localizedDescription)")
                return
            }
            guard let playlist = data?.playlist else { return }
            self.popularPlaylist = playlist
            self.PopularListView.reloadData()
        }
        
    }
    
    func setPopularCell(cell: RecommendCell, index: Int) {
        guard let playlist = self.popularPlaylist?.tracks else { return }
        let track = playlist[index]
        cell.tag = index
        
        if let url = track.al?.picUrl {
            
            let Url = url + IMAGE_PARA
            cell.idString = Url
            cell.downloadImageUsingCacheWithLink(Url, view: self.PopularListView)
        }
        cell.songNameLabel.text = track.name
        cell.songID = track.id
        
        guard let artist = track.ar else { return }
        var artistName = ""
        for item in artist {
            artistName += (item.name ?? "" + " ")
        }
        cell.artistLabel.text = artistName
    }
    
    func setNewReleaseCell(cell: RecommendCell, index: Int) {
        guard let playlist = self.newReleasePlaylist?.tracks else { return }
        let track = playlist[index]
        cell.tag = index
        if let url = track.al?.picUrl {
            
            let Url = url + IMAGE_PARA
            cell.idString = Url
            cell.downloadImageUsingCacheWithLink(Url, view: self.newReleaseView)
        }
        cell.songNameLabel.text = track.name
        cell.songID = track.id
        
        guard let artist = track.ar else { return }
        var artistName = ""
        for item in artist {
            artistName += (item.name ?? "" + " ")
        }
        cell.artistLabel.text = artistName
    }
    
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == PopularListView) {
            return popularPlaylist?.tracks?.count ?? 0
        }
        return newReleasePlaylist?.tracks?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == PopularListView) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendCell", for: indexPath) as! RecommendCell
            self.setPopularCell(cell: cell, index: indexPath.row)
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommendCell", for: indexPath) as! RecommendCell
        self.setNewReleaseCell(cell: cell, index: indexPath.row)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "musicPlayDetailID") as MusicPlayDetailViewController
        
        var playlist = self.newReleasePlaylist
        var songIndex = indexPath.row
        var tracks = self.newReleasePlaylist?.tracks
        var trackInfo = tracks?[indexPath.row]
        
        if collectionView == self.PopularListView {
            playlist = self.popularPlaylist
            tracks = self.popularPlaylist?.tracks
            trackInfo = tracks?[indexPath.row]
        }
        
        if self.delegate != nil {
            delegate?.toMusicDetailView(playlist: playlist, songIndex: songIndex, tracks: tracks, trackInfo: trackInfo)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath)->CGSize {
        return CGSizeMake(150,195)
        
    }
    
    
}

func CGSizeMake(_ width: CGFloat, _ height: CGFloat) -> CGSize {
    return CGSize(width: width, height: height)
}
