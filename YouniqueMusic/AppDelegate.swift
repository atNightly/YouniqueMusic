//
//  AppDelegate.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateCustom {
    
    
    var window: UIWindow?
    var loggedIn = false
    //    let movieLists = MyMovieListModel()
    //    let apiManager = APIManager()
    let imageCache = NSCache<NSString, UIImage>()
    var userInfo: UserInfo?
    var username : String?
    var userDefault = UserDefaults.standard
    var isFirstTime = false
    
    var player: AVPlayer!
    var playerItem:AVPlayerItem?
    var playingID: Int?
    var playingList: PlaylistDetail?
    var playingIndex: Int?
    var trackInfo: SongInfo?
    var playingMode: playerMode = .loop
    var canPlay = true
    var isFinished = true
    weak var delegate: MusicControlDelegate?
    
    let apiManager = APIManager()
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // FirebaseApp.configure()
        window = UIWindow()
        window?.makeKeyAndVisible()
        //apiManager = APIManager()
        let loggedIn = (Auth.auth().currentUser != nil)
        if !loggedIn {
            let storyboard = UIStoryboard(name: "Basic", bundle: nil)
            let controller = storyboard.instantiateViewController(identifier: "guideID") as GuideViewController
            //appDelegate.window?.rootViewController = root
            self.window?.rootViewController = controller
        } else {
            let root = RootTabBarController()
            self.window?.rootViewController = root
            self.delegate = self.window?.rootViewController as? MusicControlDelegate
            
            
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfile), name: NSNotification.Name(rawValue:"profile"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        
        return true
    }
    
    override init() {
        super.init()
        FirebaseApp.configure()
        // not really needed unless you really need it
        Database.database().isPersistenceEnabled = true
    }
    //
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didPlayToEnd() {
        isFinished = true
        switch self.playingMode {
        case .random:
            if let count = self.playingList?.tracks?.count {
                self.playingIndex = Int(arc4random()) % count
                if let url = URL(string: "\(self.playingList?.tracks?[self.playingIndex!].id)") {
                    self.trackInfo = self.playingList?.tracks?[self.playingIndex!]
                    self.delegate?.toMusicDetailView(playlist: self.playingList, songIndex: self.playingIndex!, tracks: self.playingList?.tracks, trackInfo: self.trackInfo)
                    print("random!!!!!!!!!!!!!")
                }
            }
            
        case .loop:
            if (self.playingList?.tracks?.count) != nil {
                if let index = self.playingIndex {
                    self.playingIndex = self.indexHelper(index: index + 1)
                    self.trackInfo = self.playingList?.tracks?[self.playingIndex!]
                    self.delegate?.toMusicDetailView(playlist: self.playingList, songIndex: self.playingIndex!, tracks: self.playingList?.tracks, trackInfo: self.trackInfo)
                }
                print("loop!")
            }
        case .singleLoop:
            self.player.seek(to: CMTime.zero)
            self.player.play()
             print("singleloop!")
        default:
            return
        }
        
    }
    func playerObserver() {
        //        self.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
        //            if self.player.currentItem?.status == .readyToPlay {
        //                if self.player.currentTime() == self.player!.currentItem?.asset.duration {
        //                    switch self.playingMode {
        //                    case .random:
        //                        if let count = self.playingList?.tracks?.count {
        //                            self.playingIndex = Int(arc4random()) / count
        //                            if let url = URL(string: "\(self.playingList?.tracks?[self.playingIndex!].id)") {
        //                                self.trackInfo = self.playingList?.tracks?[self.playingIndex!]
        //                                self.playerItem = AVPlayerItem(url: url)
        //                                self.player = AVPlayer(playerItem: self.playerItem)
        //                                self.player.play()
        //                                if self.player!.currentItem?.status == .readyToPlay {
        //                                    self.delegate?.toMusicDetailView(playlist: self.playingList, songIndex: self.playingIndex!, tracks: self.playingList?.tracks, trackInfo: self.trackInfo)
        //                                }
        //                            }
        //                        }
        //
        //                    case .loop:
        //                        if (self.playingList?.tracks?.count) != nil {
        //                            if let index = self.playingIndex {
        //                                self.playingIndex = self.indexHelper(index: index + 1)
        //                                if let url = URL(string: "\(self.playingList?.tracks?[self.playingIndex!].id)") {
        //                                    self.playerItem = AVPlayerItem(url: url)
        //                                    self.player = AVPlayer(playerItem: self.playerItem)
        //                                    self.player.play()
        //                                    if self.player!.currentItem?.status == .readyToPlay {
        //                                        self.delegate?.toMusicDetailView(playlist: self.playingList, songIndex: self.playingIndex!, tracks: self.playingList?.tracks, trackInfo: self.trackInfo)
        //                                    }
        //                                }
        //                            }
        //                        }
        //                    default:
        //                        return
        //                    }
        //                }
        //            }
        //        }
        //        if self.player.currentItem?.status == .failed {
        //            let alert = UIAlertController(title: "Error!", message: "\(self.player!.currentItem?.error)", preferredStyle: .alert)
        //            self.window?.rootViewController?.presentingViewController?.present(alert, animated: true, completion: nil)
        //            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
        //                self.window?.rootViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
        //            }
        //        }
    }
    
    func indexHelper(index: Int) -> Int {
        guard let count = self.playingList?.tracks?.count else {
            return 0
        }
        if index < 0 {
            return count - abs(index % count)
        }
        return index % count
    }
    
    @objc func handleProfile(noti: Notification) {
        if let data = noti.userInfo {
            if data["isFirst"] != nil {
                let storyboard = UIStoryboard(name: "Basic", bundle: nil)
                let controller = storyboard.instantiateViewController(identifier: "profileID") as ProfileViewController
                isFirstTime = true
                self.window?.rootViewController?.present(controller, animated: true)
                
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //myLists.saveLists()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        //myLists.saveLists()
    }
    
    
}

class WallpaperWindow: UIWindow {
    
    var wallpaper: UIImage? = UIImage(named: "backup") {
        didSet {
            // refresh if the image changed
            setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        //clear the background color of all table views, so we can see the background
        UITableView.appearance().backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        // draw the wallper if set, otherwise default behaviour
        if let wallpaper = wallpaper {
            wallpaper.draw(in: self.bounds);
        } else {
            super.draw(rect)
        }
    }
}
protocol AppDelegateCustom: NSObjectProtocol{
    func playerObserver()
}
