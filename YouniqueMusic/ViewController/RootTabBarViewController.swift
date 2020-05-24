//
//  RootTabBarViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import AVFoundation

class RootTabBarController: UITabBarController, MusicControlDelegate, UINavigationControllerDelegate{
    
    
    var tabArray: [UITableViewController] = []
    var musicView = MusicView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 46))
    var playlist: PlaylistDetail?
    var songIndex = 0
    var trackInfo: SongInfo?
    weak var appDelegate = UIApplication.shared.delegate as! AppDelegate
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.creatSubViewControllers()
        //self.view.layer.contents = UIImage(named:"bg1")?.cgImage
        self.view.backgroundColor = UIColor(patternImage: UIImage(named:"bg1")!)
        setNeedsStatusBarAppearanceUpdate()
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true;
    }
    
    
    func setUI() {
        self.view.addSubview(musicView)
        musicView.backgroundColor = UIColor(red: 46 / 255, green: 59 / 255, blue: 70 / 255, alpha: 1)
        musicView.translatesAutoresizingMaskIntoConstraints = false
        musicView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        musicView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let height = -1 - Float(self.tabBar.inputView?.frame.height ?? 45)
        musicView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: CGFloat(height)).isActive = true
        musicView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor).isActive = true
        musicView.playButton.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        setDetail()
        
    }
    
    @objc func handlePlay() {
        if appDelegate?.player.currentItem == nil {
            self.musicView.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            let alert = UIAlertController(title: "Music can not be played", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        }
        if appDelegate?.player?.rate == 0 {
            appDelegate?.player!.play()
            appDelegate?.isFinished = false
            self.musicView.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        } else {
            appDelegate?.player!.pause()
            self.musicView.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            
        }
    }
    
    func setDetail() {
        if(trackInfo != nil) {
            var artistName = ""
            if let artist = trackInfo?.ar {
                for item in artist {
                    artistName += (item.name ?? "" + " ")
                }
            }
            var songName = ""
            if let name = self.trackInfo?.name {
                songName = name
            }
            self.musicView.songLabel.text = (songName + "  -  " + artistName)
            guard let url = trackInfo?.al?.picUrl else { return }
            self.musicView.songImageView.downloadImageUsingCacheWithLink(url)
        }
        
        if appDelegate?.player?.rate == 0 {
            self.musicView.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        } else {
            self.musicView.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        }
    }
    func creatSubViewControllers(){
        
        // let bgclor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeVC = storyboard.instantiateViewController(identifier: "homeID") as HomeViewController
        let homeNvc = UINavigationController(rootViewController:homeVC)
        homeVC.title = "Home"
        // homeNvc.navigationBar.barTintColor = .clear
        homeNvc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        homeNvc.navigationBar.isTranslucent = true
        homeNvc.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        homeNvc.tabBarItem =  UITabBarItem(title: "Home", image: UIImage(named: "Home Icon"),
                                           selectedImage: UIImage(named: "Home Icon (selected)")?.withRenderingMode(.alwaysOriginal))
        homeNvc.tabBarItem.tag = 0
        homeVC.delegate = self
        
        
        
        let storyboard1 = UIStoryboard(name: "Library", bundle: nil)
        let libraryVC = storyboard1.instantiateViewController(identifier: "libraryID") as LibraryViewController
        let libraryNvc = UINavigationController(rootViewController:libraryVC)
        libraryVC.title = "Library"
        libraryNvc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        libraryNvc.navigationBar.isOpaque = true
        libraryNvc.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        libraryNvc.tabBarItem =  UITabBarItem(title: "Library", image: UIImage(named: "Library Icon (notification)"),
                                              selectedImage: UIImage(named: "Library Icon (selected)")?.withRenderingMode(.alwaysOriginal))
        libraryVC.delegate = self
        
        
        
        let storyboard2 = UIStoryboard(name: "Search", bundle: nil)
        let searchVC = storyboard2.instantiateViewController(identifier: "searchID") as SearchViewController
        let searchNvc = UINavigationController(rootViewController:searchVC)
        searchVC.title = "Search"
        //searchNvc.navigationBar.barTintColor = .clear
        searchNvc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        searchNvc.navigationBar.isOpaque = true
        searchNvc.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        searchNvc.tabBarItem =  UITabBarItem(title: "Search", image: UIImage(named: "Search Icon"),
                                             selectedImage: UIImage(named: "Search Icon(select)")?.withRenderingMode(.alwaysOriginal))
        searchVC.delegate = self

        let tabArray = [homeNvc, searchNvc, libraryNvc]
        self.viewControllers = tabArray
        
    }
    
    
}

extension RootTabBarController {
    
    func playNewSong(playlist: PlaylistDetail, index: Int) {
        
    }
    func toMusicDetailView(controller: LibraryViewController) {
         if appDelegate?.playerItem == nil {
            let alert = UIAlertController(title: "No music in list now", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        } else if appDelegate?.player.status == .readyToPlay {
            let storyboard = UIStoryboard(name: "Basic", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "musicPlayDetailID") as MusicPlayDetailViewController
            vc.songIndex = self.songIndex
            vc.playlist = self.playlist
            vc.trackInfo = self.trackInfo
            controller.navigationController?.tabBarController?.tabBar.isHidden = true
            verticalPushAnimated(Controller: controller.navigationController!)
            controller.navigationController?.pushViewController(vc, animated: false)
        } else {
            let alert = UIAlertController(title: "Not Ready", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        }
        
    }
    
    func toMusicDetailView(controller: SearchViewController) {
         if appDelegate?.playerItem == nil {
            let alert = UIAlertController(title: "No music in list now", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
            
//            appDelegate?.apiManager.downloadSongJSON(url: SONG_URL + "\(id)"){ (data, error) in
//            if let error = error {
//                print("No data asvailable \(error.localizedDescription)")
//                return
//            }
//            }
        }
        
        else if appDelegate?.player.status == .readyToPlay {
            //self.musicView.isHidden = true
            let storyboard = UIStoryboard(name: "Basic", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "musicPlayDetailID") as MusicPlayDetailViewController
            vc.songIndex = self.songIndex
            vc.playlist = self.playlist
            vc.trackInfo = self.trackInfo
            controller.navigationController?.tabBarController?.tabBar.isHidden = true
            verticalPushAnimated(Controller: controller.navigationController!)
            controller.navigationController?.pushViewController(vc, animated: false)
            appDelegate?.playerObserver()
        } else {
            let alert = UIAlertController(title: "Not Ready", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        }
    }
    
    func toMusicDetailView(controller: HomeViewController) {
        if appDelegate?.playerItem == nil {
            let alert = UIAlertController(title: "No music in list now", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        }
        
        else if appDelegate?.player.status == .readyToPlay  {
           // self.musicView.isHidden = true
            let storyboard = UIStoryboard(name: "Basic", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "musicPlayDetailID") as MusicPlayDetailViewController
            vc.songIndex = self.songIndex
            vc.playlist = self.playlist
            vc.trackInfo = self.trackInfo
            controller.navigationController?.tabBarController?.tabBar.isHidden = true
            verticalPushAnimated(Controller: controller.navigationController!)
            controller.navigationController?.pushViewController(vc, animated: false)
        } else {
            let alert = UIAlertController(title: "Not Ready", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                return
            }
        }
        
    }
//    
//    func toMusicDetailView(controller: HomeViewController, secondVC: MusicPlayDetailViewController) {
//        self.musicView.isHidden = true
//        self.playlist = secondVC.playlist
//        self.songIndex = secondVC.songIndex
//        self.trackInfo = secondVC.trackInfo
//        verticalPushAnimated(Controller: controller.navigationController!)
//        controller.navigationController?.pushViewController(secondVC, animated: false)
//    }
//    
//    func toMusicDetailView(controller: LibraryViewController, secondVC: MusicPlayDetailViewController) {
//        self.musicView.isHidden = true
//        self.playlist = secondVC.playlist
//        self.songIndex = secondVC.songIndex
//        self.trackInfo = secondVC.trackInfo
//        verticalPushAnimated(Controller: controller.navigationController!)
//        controller.navigationController?.pushViewController(secondVC, animated: false)
//        
//    }
//    
//    func toMusicDetailView(controller: SearchViewController, secondVC: MusicPlayDetailViewController) {
//        self.musicView.isHidden = true
//        self.playlist = secondVC.playlist
//        self.songIndex = secondVC.songIndex
//        self.trackInfo = secondVC.trackInfo
//        verticalPushAnimated(Controller: controller.navigationController!)
//        controller.navigationController?.pushViewController(secondVC, animated: false)
//    }
    
    func setMusicView(controller: MusicPlayDetailViewController) {
        self.playlist = controller.playlist
        self.songIndex = controller.songIndex
        self.trackInfo = controller.trackInfo
        self.appDelegate?.playingList = self.playlist
        self.appDelegate?.playingIndex = self.songIndex
        self.appDelegate?.trackInfo = self.trackInfo
        setDetail()
    }
    
    func toMusicDetailView(playlist: PlaylistDetail?, songIndex: Int, tracks: [SongInfo]?, trackInfo: SongInfo?) {
        
        self.playlist = playlist
        self.songIndex = songIndex
        self.trackInfo = trackInfo
        self.appDelegate?.playingList = self.playlist
        self.appDelegate?.playingIndex = self.songIndex
        self.appDelegate?.trackInfo = self.trackInfo
        
        self.appDelegate?.player?.pause()
        guard let id = playlist?.tracks?[songIndex].id else {return}
        if id != appDelegate?.playingID {
            guard let tracks = playlist?.tracks else { return }
            guard let id = tracks[songIndex].id else { return }
            appDelegate?.apiManager.downloadSongJSON(url: SONG_URL + "\(id)"){ (data, error) in
                if let error = error {
                    print("No data asvailable \(error.localizedDescription)")
                    return
                }
                self.appDelegate?.playingID = id
                self.setDetail()
                
                guard let url = data?.data.first?.url else {
                    self.appDelegate?.canPlay = false
                let alert = UIAlertController(title: "No Music Resource Available!", message: nil, preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                        self.presentedViewController?.dismiss(animated: false, completion: nil)
                    }
                    self.musicView.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
                    return
                    
                }
                guard let link = URL(string: url) else {
                    self.appDelegate?.canPlay = false
                   let alert = UIAlertController(title: "No Music Resource Available!", message: nil, preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                        self.presentedViewController?.dismiss(animated: false, completion: nil)
                    }
                    self.musicView.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
                    return
                }
                self.appDelegate?.canPlay = true
                self.appDelegate?.playerItem = AVPlayerItem(url: link)
                self.appDelegate?.player = AVPlayer(playerItem: self.appDelegate?.playerItem!)
                self.appDelegate?.player?.play()
                self.appDelegate?.isFinished = false
                
                self.musicView.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
//                if self.musicView.isHidden {
//                    self.musicView.isHidden = false
//                }
                
            }
        }
    }
}

class MusicView: UIView {
    var songImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        view.layer.borderColor = .init(srgbRed: 255.0, green: 255.0, blue: 255.0, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var songLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .gray
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        return button
    }()
    
    var border: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray
        return view
    }()
    
    override init(frame: CGRect) {
        
        super.init(frame:frame)
        //self.addSubview(blurView)
        self.addSubview(songImageView)
        self.addSubview(songLabel)
        self.addSubview(playButton)
        self.addSubview(border)
        setUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setUI() {
        
        songImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        songImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        songImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        songLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        songImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 5).isActive = true
        songImageView.rightAnchor.constraint(equalTo: self.leftAnchor, constant: 45).isActive = true
        
        playButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        playButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
        
        songLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        songLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        songLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        songLabel.rightAnchor.constraint(equalTo: playButton.leftAnchor, constant: 10).isActive = true
        songLabel.leftAnchor.constraint(equalTo: songImageView.rightAnchor, constant: 5).isActive = true
        
        border.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1)
        border.heightAnchor.constraint(equalToConstant: 1).isActive = true
        border.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        border.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        border.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        border.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
    }
    
    
}

extension UIViewController {
    class func current(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return current(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return current(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return current(base: presented)
        }
        return base
    }
}
