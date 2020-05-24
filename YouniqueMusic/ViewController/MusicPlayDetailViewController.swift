//
//  MusicPlayDetailViewController.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase


enum playerMode {
    case random
    case loop
    case singleLoop
    case none
}

class MusicPlayDetailViewController: UIViewController,MusicDetailControlDelegate,  UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var loopButton: UIButton!
    @IBOutlet var shuffleButton: UIButton!
    @IBOutlet var trackImageView: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var finalTimeLabel: UILabel!
    @IBOutlet var playbackSlider: UISlider!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var playlistTableView: UITableView!
    @IBOutlet var bgImageView: UIImageView!
    @IBOutlet var lyricView: UIControl!
    @IBOutlet var lyricTextView: UITextView!
    
    let ref = Database.database().reference()
    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
    var songList: [String] = []
    var playlist: PlaylistDetail?
    var songIndex = 0
    var trackInfo: SongInfo?
    var isTabIn = true
    var delegate: MusicControlDelegate?
    var isliked = false
    var playlistNames: [String] = []
    var playlistIDs:[String] = []
    var setPid: String?
    var lyricText = ""
    var pObserver: Any?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if pObserver != nil {
            appDelegate?.player.removeTimeObserver(pObserver)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restorationIdentifier = "MusicPlayDetailViewController"
        switch self.appDelegate?.playingMode {
        case .loop:
            loopButton.setImage(UIImage(systemName: "repeat"), for: .normal)
        case .random:
            shuffleButton.setImage(UIImage(systemName: "shuffle"), for: .normal)
        case .singleLoop:
            loopButton.setImage(UIImage(systemName: "repeat.1"), for: .normal)
        default:
            break
        }
        shuffleButton.isHighlighted = self.appDelegate?.playingMode == .random
        loopButton.isHighlighted = self.appDelegate?.playingMode == .loop
        
        playlistTableView.dataSource = self
        playlistTableView.delegate = self
        playlistTableView.rowHeight = 80
        if let img = UIImage(named: "bg1"){
            playlistTableView.backgroundColor = UIColor(patternImage: img )
        }
        bgImageView.isUserInteractionEnabled = true
        bgImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchBackgound(tapGestureRecognizer:))))
        
        trackImageView.isUserInteractionEnabled = true
        trackImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showLyric(tapGestureRecognizer:))))
        
        lyricTextView.isUserInteractionEnabled = true
        lyricTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideLyric(tapGestureRecognizer:))))
        lyricTextView.isEditable = false
        
        delegate = appDelegate?.window?.rootViewController as? MusicControlDelegate
        if self.playlist?.tracks?[songIndex].id !=  appDelegate?.playingID {
            playRequest()
            //            self.delegate?.setMusicView(controller: self)
        } else {
            playSetUp()
        }
        setUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let views = self.appDelegate?.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            
            view.isHidden = true
        }
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        playlistTableView.reloadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let views = self.appDelegate?.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            
            view.isHidden = false
        }
        self.navigationController?.navigationBar.isHidden = false
//        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.view.endEditing(true)
        
        
    }
    
    @objc func didPlayToEnd() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.clearUI()
            self.playlist = self.appDelegate?.playingList
            self.songIndex = self.appDelegate?.playingIndex ?? 0
            self.trackInfo = self.appDelegate?.trackInfo
            self.setUI()
            self.playSetUp()
        }
        
        
    }
    func downloadLyric() {
        guard let id = appDelegate?.playingID else {return}
        appDelegate?.apiManager.downloadLyricJSON(url: LYRIC_SEARCH_URL + "\(id)"){ (data, error) in
            if let error = error {
                print("No data asvailable \(error.localizedDescription)")
                return
            }
            print("")
            self.lyricText = lyricHandler(lric: data?.lrc?.lyric)
            print(self.lyricText)
            self.lyricTextView.text = self.lyricText
            self.lyricView.isHidden = false
        }
    }
    
    @IBAction func showLyricView(_ sender: Any) {
        self.lyricView.isHidden = true
    }
    
    @objc func hideLyric(tapGestureRecognizer: UITapGestureRecognizer) {
        self.lyricView.isHidden = true
    }
    
    @objc func showLyric(tapGestureRecognizer: UITapGestureRecognizer) {
        downloadLyric()
        
    }
    
    @objc func touchBackgound(tapGestureRecognizer: UITapGestureRecognizer) {
        self.playlistTableView.isHidden = true
    }
    
    func observeHandler() {
        guard let currentID = Auth.auth().currentUser?.uid else { return }
        guard let mid = self.playlist?.tracks?[songIndex].id else { return }
        self.ref.child("playlist").child(currentID).child("favourite").child("tracks").observeSingleEvent(of: .value, with: { (snap) in
            if snap.hasChild(String(mid)){
                self.isliked = true
                self.likeButton.imageView?.image = UIImage(systemName: "heart.fill")
            }else{
                self.isliked = false
                self.likeButton.imageView?.image = UIImage(systemName: "heart")
            }
        })
        
    }
    
    func playRequest() {
        guard let tracks = playlist?.tracks else { return }
        guard let id = tracks[songIndex].id else { return }
        appDelegate?.apiManager.downloadSongJSON(url: SONG_URL + "\(id)"){ (data, error) in
            if let error = error {
                print("No data asvailable \(error.localizedDescription)")
                return
            }
            self.appDelegate?.playingID = id
            guard let url = data?.data.first?.url else {
                self.appDelegate?.canPlay = false
                let alert = UIAlertController(title: "No Music Resource Available!", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
                self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.appDelegate?.player.replaceCurrentItem(with: nil)
                self.setUI()
                return
            }
            guard let link = URL(string: url) else {
                self.appDelegate?.canPlay = false
                let alert = UIAlertController(title: "No Music Resource Available!", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
                self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.appDelegate?.player.replaceCurrentItem(with: nil)
                self.setUI()
                return
                
            }
            self.appDelegate?.canPlay = true
            self.appDelegate?.playerItem = AVPlayerItem(url: link)
            self.appDelegate?.player = AVPlayer(playerItem: self.appDelegate?.playerItem!)
            self.appDelegate?.player.play()
            self.appDelegate?.isFinished = false
            self.playButton.setImage(UIImage(named: "Pause"), for: .normal)
            self.delegate?.setMusicView(controller: self)
            self.playSetUp()
            self.setUI()
        }
    }
    
    func playSetUp() {
        if appDelegate?.playerItem != nil {
            guard let duration : CMTime = appDelegate?.playerItem!.asset.duration  else {return}
            let seconds : Float64 = CMTimeGetSeconds(duration)
            playbackSlider!.minimumValue = 0
            playbackSlider!.maximumValue = Float(seconds)
            finalTimeLabel.text = timeHelper(time: seconds)
            playbackSlider!.isContinuous = false
            
            self.pObserver = appDelegate?.player!.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
                if self.appDelegate?.player!.currentItem?.status == .readyToPlay {
                    guard let ct = self.appDelegate?.player!.currentTime() else{return}
                    let currentTime = CMTimeGetSeconds(ct)
                    self.playbackSlider!.value = Float(currentTime)
                    let time = self.timeHelper(time: currentTime)
                    self.currentTimeLabel.text = time
                }
            }
        }
    }
    
    func setUI() {
        // if self.playlist?.tracks?[songIndex].id ==  appDelegate?.playingID {
        observeHandler()
        
        if(trackInfo != nil) {
            var artistName = ""
            if let artist = trackInfo?.ar {
                for item in artist {
                    artistName += (item.name ?? "" + " ")
                }
            }
            self.artistLabel.text = artistName
            self.songNameLabel.text = trackInfo?.name
            guard let url = trackInfo?.al?.picUrl else { return }
            let Url = url + IMAGE_PARA
            downloadImageUsingCacheWithLink(Url, imageView: self.trackImageView)
        }
        print(self.appDelegate?.canPlay)
        if self.appDelegate?.canPlay ?? false {
            if let duration = appDelegate?.playerItem?.asset.duration {
                let seconds : Float64 = CMTimeGetSeconds(duration)
                playbackSlider!.minimumValue = 0
                playbackSlider!.maximumValue = Float(seconds)
                finalTimeLabel.text = timeHelper(time: seconds)
                playbackSlider!.isContinuous = false
                
                if let ctime = self.appDelegate?.player?.currentTime() {
                    let currentTime = CMTimeGetSeconds(ctime)
                    self.playbackSlider!.value = Float(currentTime)
                    let time = self.timeHelper(time: currentTime)
                    self.currentTimeLabel.text = time
                    if appDelegate?.player?.rate == 0 {
                        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    } else {
                        playButton.setImage(UIImage(named: "Pause"), for: .normal)
                    }
                }
            }
        }
        
    }
    
    func clearUI() {
        print("enter clear ui")
        currentTimeLabel.text = "--:--"
        finalTimeLabel.text = "00:00"
        self.playbackSlider!.value = 0.0
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        
        self.artistLabel.text = ""
        self.songNameLabel.text = ""
        self.trackImageView.image = UIImage(named:"Player ICON")
    }
    func downloadImageUsingCacheWithLink(_ urlLink: String, imageView: UIImageView) {
        
        if let cachedImage = appDelegate?.imageCache.object(forKey: urlLink as NSString) {
            imageView.image = cachedImage
            return
        }
        let url = URL(string: urlLink)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let err = error {
                print(err)
                return
            }
            DispatchQueue.main.async {
                if let newImage = UIImage(data: data!) {
                    self.appDelegate?.imageCache.setObject(newImage, forKey: urlLink as NSString)
                    imageView.image = newImage
                    
                }
            }
        }).resume()
    }
    
    
    @IBAction func closeButtonAction(_ sender: Any) {
        if let views = appDelegate?.window?.rootViewController?.view.subviews.filter({$0 is MusicView}) {
            let view = views[0] as! MusicView
            view.isHidden = false
            
            if appDelegate?.player?.rate == 0 {
                view.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            } else {
                view.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            }
        }
        self.lyricView.isHidden = true
        self.playlistTableView.isHidden = true
        verticalPopAnimated(Controller: self.navigationController!)
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func viewComment(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "commentID") as CommentViewController
        controller.musicID = "\(self.appDelegate?.playingID ?? -1)"
        controller.trackInfo = self.trackInfo
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func addToList(_ sender: Any) {
        self.playlistNames = []
        self.playlistIDs = []
        self.playlistTableView.reloadData()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        ref.child("playlist").child(uid).observeSingleEvent(of: .value, with: { (snap) in
            for child in snap.children {
                let snap = child as! DataSnapshot
                let key = snap.key as String
                let dict = snap.value as? [String: AnyObject]
                print (dict)
                if key != "favourite" {
                    if let playlist = dict {
                        if let name = playlist["name"] as? String, let id = playlist["id"] as? String {
                            self.playlistNames.append(name )
                            self.playlistIDs.append(id )
                        }
                    }
                }
            }
            
            self.playlistTableView.isHidden = false
            self.playlistTableView.reloadData()
        })
    }
    
    @IBAction func likeAction(_ sender: Any) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let mid = self.playlist?.tracks?[songIndex].id else { return }
        let track = self.playlist?.tracks?[songIndex]
        self.setPid = "favourite"
        if !self.isliked {
            setDatabseValue()
        } else {
            guard let pid = self.setPid else{return}
            ref.child("playlist").child(uid).child(pid).child("tracks").child(String(mid)).removeValue(completionBlock: { (err, ref) in
                if err != nil {
                    print(err ?? "")
                    return
                }
                self.likeButton.imageView?.image = UIImage(systemName: "heart")
                self.isliked = false
            })
        }
        
    }
    
    func setDatabseValue() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let mid = self.playlist?.tracks?[songIndex].id else { return }
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
        let newId = ref.child("playlist").child(uid).child("comments").childByAutoId().key ?? randomString(length: 10)
        
        guard let pid = self.setPid else{return}
        var like = false
        if pid == "favourite" {
            like = true
        }
        let pdic = ["profile_url": alDict["picUrl"]]
        let timeInterval:TimeInterval = Date().timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        ref.child("playlist").child(uid).child(pid).updateChildValues(pdic as [AnyHashable : Any])
        let values = ["id": id, "artist": arDict, "name": name, "album": alDict, "liked": like, "timestamp": timeStamp] as [String: Any]
        ref.child("playlist").child(uid).child(pid).child("tracks").child(String(mid)).updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err ?? "")
                return
            }
            if pid == "favourite" {
                self.likeButton.imageView?.image = UIImage(systemName: "heart.fill")
                self.isliked = true
            }
            
        })
    }
    
    
    @IBAction func viewList(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "playlistID") as PlayListDetailViewController
        controller.pid = self.playlist?.pid
        if self.playlist?.pid == nil {
            controller.customerPlaylist = self.playlist
        }
        controller.delegate = self
        controller.fromMusic = true
        controller.playlist = self.playlist
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func shuffleAction(_ sender: Any) {
        //songIndex = Int(arc4random()) / count
        self.appDelegate?.playingMode = .random
        shuffleButton.setImage(UIImage(systemName: "shuffle"), for: .normal)
        loopButton.setImage(UIImage(named: "Repeat"), for: .normal)
    }
    
    @IBAction func previous(_ sender: Any) {
        clearUI()
        if let count = self.playlist?.tracks?.count {
            if self.appDelegate?.playingMode == .random {
                self.songIndex = Int(arc4random()) % count
            } else {
                self.songIndex -= 1
            }
            songIndex = indexHelper(index: songIndex)
            trackInfo = playlist?.tracks?[songIndex]
            playRequest()
            //setUI()
            self.delegate?.setMusicView(controller: self)
        }

    }
    
    @IBAction func next(_ sender: Any) {
        clearUI()
        if let count = self.playlist?.tracks?.count {
            if self.appDelegate?.playingMode == .random {
                self.songIndex = Int(arc4random()) % count
            } else {
                self.songIndex += 1
            }
            songIndex = indexHelper(index: songIndex)
            trackInfo = playlist?.tracks?[songIndex]
            playRequest()
            self.delegate?.setMusicView(controller: self)
        }
        
        
    }
    @IBAction func play(_ sender: Any) {
        if !(self.appDelegate?.canPlay ?? false) {
            let alert = UIAlertController(title: "No Music Resource Available!", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
            return
        }
        if appDelegate?.player?.rate == 0 {
            appDelegate?.player!.play()
            appDelegate?.isFinished = false
            playButton.setImage(UIImage(named: "Pause"), for: .normal)
        } else {
            appDelegate?.player!.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    @IBAction func changeSlider(_ sender: Any) {
        let seconds : Int64 = Int64(playbackSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        appDelegate?.player!.seek(to: targetTime)
        if appDelegate?.player!.rate == 0
        {
            appDelegate?.player?.play()
            appDelegate?.isFinished = false
        }
    }
    
    @IBAction func loop(_ sender: Any) {
        if self.appDelegate?.playingMode == .loop {
            self.loopButton.setImage(UIImage(systemName: "repeat.1"), for: .normal)
            self.appDelegate?.playingMode = .singleLoop
        } else {
            self.loopButton.setImage(UIImage(systemName: "repeat"), for: .normal)
            self.appDelegate?.playingMode = .loop
        }
        self.shuffleButton.setImage(UIImage(named: "Shuffle"), for: .normal)
    }
    
    func timeHelper(time: Float64) -> String {
        if time.isNaN {
            return "00:00"
        }
        let all: Int = Int(time)
        let m: Int=all % 60
        let f: Int=Int(all/60)
        var time: String=""
        if f < 10{
            time = "0\(f):"
        }else {
            time = "\(f)"
        }
        if m < 10{
            time += "0\(m)"
        }else {
            time += "\(m)"
        }
        return time
    }
    
    func indexHelper(index: Int) -> Int {
        guard let count = self.playlist?.tracks?.count else {
            return 0
        }
        if index < 0 {
            return count - abs(index % count)
        }
        return index % count
    }
    
}

extension MusicPlayDetailViewController {
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "normalID", for: indexPath) as UITableViewCell
        
        cell.textLabel?.text = playlistNames[indexPath.row]
        cell.textLabel?.textColor = .lightGray
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let pid = self.playlistIDs[indexPath.row]
        self.setPid = pid
        setDatabseValue()
        scrollToFirstRow()
        let alert = UIAlertController(title: "Add to List", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            tableView.isHidden = true
            return
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.0)
        let viewLabel = UILabel(frame: CGRect(x: 10, y: 0, width: UIScreen.main.bounds.size.width, height: 30))
        viewLabel.text = "Add to list"
        viewLabel.textColor = UIColor(red:0.31, green:0.31, blue:0.31, alpha:1.0)
        view.addSubview(viewLabel)
        tableView.addSubview(view)
        return view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistNames.count
    }
    
    func scrollToFirstRow() {
        let indexPath = IndexPath(row: 0, section: 0)
        self.playlistTableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    
}

extension MusicPlayDetailViewController {
    
    func refreshPlayingSong(playlist: PlaylistDetail?, index: Int) {
        if self.playlist?.pid != playlist?.pid || self.playlist?.id != playlist?.id || self.playlist?.tracks?.count != playlist?.tracks?.count{
            self.playlist = playlist
        } else if index != self.songIndex {
            if self.playlist?.tracks?.count != playlist?.tracks?.count {
                self.playlist = playlist
            }
            self.songIndex = indexHelper(index: index)
            self.trackInfo = self.playlist?.tracks?[self.songIndex]
            self.clearUI()
            self.playRequest()
        } else if index == self.songIndex {
            if self.playlist?.tracks?.count != playlist?.tracks?.count {
                self.playlist = playlist
            }
            self.songIndex = indexHelper(index: index)
            self.trackInfo = self.playlist?.tracks?[self.songIndex]
            self.clearUI()
            self.playRequest()
        }
        
    }
    
    func refreshPlayingList(playlist: PlaylistDetail?) {
        self.playlist = playlist
        var index = 0
        if let tracks = playlist?.tracks {
            for track in tracks {
                if track.id == appDelegate?.playingID {
                    self.songIndex = index
                }
                index += 1
            }
        }
            self.trackInfo = self.playlist?.tracks?[self.songIndex]
        
        delegate?.setMusicView(controller: self)
    }
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func lyricHandler(lric: String?) -> String {
    
    guard let lrc = lric else {return "No Lyric Available Now!!"}
    let tempLrc = lrc.components(separatedBy: "\n").filter { $0 != "" }
    var string = ""
    for j in 0 ..< tempLrc.count {
        var arrContentLRC = tempLrc[j].components(separatedBy: "]")
        
        if("0123456789".components(separatedBy:(arrContentLRC[0] as NSString).substring(with: NSMakeRange(1, 1))).count > 1) {
            for k in 0..<(arrContentLRC.count - 1) {
                if arrContentLRC[k].contains("[") {
                    arrContentLRC[k] = (arrContentLRC[k] as NSString).substring(from: 1)
                }
            }
        }
        let char1 : Character = "0"
        let char2 : Character = "9"
        for item in arrContentLRC {
            if let c = item.first {
                if c < char1 || c > char2 {
                    string = string + item + "\n"
                }
            }
        }
    }
    return string
}
