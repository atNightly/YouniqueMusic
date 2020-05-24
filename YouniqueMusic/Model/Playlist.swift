//
//  Playlist.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import Foundation
import Firebase

class PlaylistInfo {
    var uid: String?
    var id: String?
    var profileURL: String?
    var name: String?
    var username: String?
    var timestamp: String?
    var tracks: [SongInfo]?
    
    init(key: String, dict: [String:Any]) {
        id = key
        uid = dict["uid"] as? String
        timestamp = dict["timestamp"] as? String
        self.name = dict["name"] as? String
        if uid != nil {
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.username = dictionary["username"] as? String
                    self.profileURL = dict["profile_url"] as? String
                }
                
            }, withCancel: nil)
        } else {
            self.username = "creator"
        }
        
        guard let songs = dict["tracks"] as? [AnyObject] else { return }
        tracks = []
        for song in songs {
            let id = song["id"] as? Int
            let name = song["name"] as? String
            let picURL = song["picURL"] as? String
            if self.profileURL == nil {
                self.profileURL = picURL
            }
            let timestamp = song["timestamp"] as? String
            let liked = song["liked"] as? Bool
            
            var artistArray: [Artist] = []
            if let artists = song["artist"] as? [AnyObject] {
                for artist in artists {
                    let id = artist["id"] as? Int
                    let name = artist["name"] as? String
                    let a = Artist(id: id, name: name)
                    artistArray.append(a)
                }
                
                var al: Album?
                if let album = song["album"] as? [String: AnyObject] {
                    let id = album["id"] as? Int
                    let name = album["name"] as? String
                    let picUrl = album["picUrl"] as? String
                    let pic = album["pic"] as? Int
                    let pic_str = album["pic_str"] as? String
//                    let aDict = ["id": id, "name": name, "picUrl": picUrl, "pic": pic, "pic_str": pic_str]
                    al = Album(id: id, name: name, picUrl: picUrl, pic_str: pic_str, pic: pic)
                }
                //let pDict = [name: name, id: id, ar: artistArray, al: al] as [String : AnyObject]
                let sItem = SongInfo(name: name, id: id, ar: artistArray, al: al, liked: liked, timestamp: timestamp)
                self.tracks?.append(sItem)
            }
            
        }
    }
}


class PlaylistItem {
    var id: Int?
    var name: String?
    var picURL: String?
    var timestamp: String?
    var artists: [Artist]?
    var album: Album?
    
    init(dict: [String: Any]) {
        id = dict["id"] as? Int
        name = dict["name"] as? String
        picURL = dict["picURL"] as? String
        timestamp = dict["timestamp"] as? String
        artists = dict["artist"] as? [Artist]
        album = dict["album"] as? Album
    }
    
}

class Playlists {
    var playistLists : [PlaylistInfo] = []
    
    func remove(key: String) -> Int {
        var index = 0
        for playlist in playistLists {
            
            if key == playlist.id {
                playistLists.remove(at: index)
                return index
            }
            index += 1
        }
        return -1
    }
    func removeAll() {
        playistLists = []
    }
    
    func append(playlist: PlaylistInfo) {
        playistLists.append(playlist)
    }
    
    func update(playlistItem: PlaylistInfo) {
        var index = -1
        var isFind = false
        for playlist in playistLists {
            index += 1
            if playlist.id == playlistItem.id {
                isFind = true
                break
            }
        }
        if isFind {
            playistLists[index] = playlistItem
        }
    }
}

