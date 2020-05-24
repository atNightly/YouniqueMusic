//
//  CustomPlayListViewController.swift
//  YouniqueMusic
//
//  Created by xww on 4/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit



class CustomPlayListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var segament: UISegmentedControl!
    @IBOutlet var playlistTableView: UITableView!
    var type: listType = .history
    var tracks: [SongInfo]?
    var playlist:PlaylistDetail?
    var navTitle: String = "playing list"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 27 / 255, green: 42 / 255, blue: 55 / 255, alpha: 0.98)
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        playlistTableView.rowHeight = 80
        
        self.navigationController?.tabBarController?.tabBarItem.title = navTitle
        observeSongList()
    }
    
    func observeSongList() {
        
    }
    
    func setCell(cell: PlayListCell, index: IndexPath) {
        cell.songNameLabel.text = tracks?[index.row].name
        var artistName = ""
        if let artist = tracks?[index.row].ar {
            for item in artist {
                artistName += (item.name ?? "" + " ")
            }
        }
        cell.artistLabel.text = artistName
        if let url = tracks?[index.row].al?.picUrl{
            downloadImageUsingCacheWithLink(url, imageView: cell.trackImage)
        }
    }
    
    func downloadImageUsingCacheWithLink(_ urlLink: String, imageView: UIImageView) {

        if let cachedImage = appDelegate.imageCache.object(forKey: urlLink as NSString) {
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
                    self.appDelegate.imageCache.setObject(newImage, forKey: urlLink as NSString)
                    imageView.image = newImage
                    
                }
            }
        }).resume()
    }
    
}

extension CustomPlayListViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tracks = playlist?.tracks {
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
        
        let storyboard = UIStoryboard(name: "Basic", bundle: nil)
        let controller = storyboard.instantiateViewController(identifier: "musicPlayDetailID") as MusicPlayDetailViewController
        controller.isTabIn = false
        guard let detail = self.playlist else { return }
        var songs: [SongInfo] = []
        if let tracks = self.tracks {
            for track in tracks {
                
            }
        }
        
        controller.playlist = self.playlist
        controller.songIndex = indexPath.row
        let tracks = self.tracks
        controller.trackInfo = tracks?[indexPath.row]
        verticalPushAnimated(Controller: self.navigationController!)
        self.navigationController?.pushViewController(controller, animated: false)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
}


