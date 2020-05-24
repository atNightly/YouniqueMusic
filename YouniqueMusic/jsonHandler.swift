//
//  jsonHandler.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import Foundation
import UIKit

let SearchURL = ""
let SONG_URL = "https://api.imjad.cn/cloudmusic/?type=song&id="
let LYRIC_URL = "https://api.imjad.cn/cloudmusic/?type=lyric&id="
let SONG_DETAIL_URL = "https://api.imjad.cn/cloudmusic/?type=detail&id="
let SONG_SEARCH_URL = "https://music-api-jwzcyzizya.now.sh/api/search/song/netease?key="
let PLAYLIST_URL = "https://api.imjad.cn/cloudmusic/?type=playlist&id="
let IMAGE_PARA = "?param=140y140"
let LYRIC_SEARCH_URL = "https://api.a632079.me/nm/lyric/"
let LIMIT_INDEX = "&limit=30&page=1"
let SEARCH_URL = "https://api.a632079.me/nm/search/"
let ARTIST_SONGS_URL =  "https://api.imjad.cn/cloudmusic/?type=artist&id="

class APIManager {
//    override func viewDidLoad() {
//        super.viewDidLoad()
        
//         downloadJSON {
 //                   print("JSON download successful")
//                    print(self.song?.data[0].id)
//                    print(self.song?.data[0].url)
//                    print(self.lyric?.lrc?.lyric)
//            print(self.songDetail?.songs[0].name)
//            print(self.songDetail?.songs[0].al?.name)
//            print(self.songDetail?.songs[0].ar[0].name)

//            print(self.playlist?.creator?.nickname)
//            print(self.playlist?.tags)
//            print(self.playlist?.name)
//            print(self.playlist?.tracks![0].name)
//            print(self.search?.total)
//            print(self.search?.songList[0].album?.name)
//                }
//    }
    
        //https://api.imjad.cn/cloudmusic/?type=song&id=1384570306
        //https://api.imjad.cn/cloudmusic/?type=lyric&id=1384570306
        //https://api.imjad.cn/cloudmusic/?type=detail&id=1384570306
        //https://api.imjad.cn/cloudmusic/?type=lyric&id=1384570306
    //https://music-api-jwzcyzizya.now.sh/api/search/song/netease?key=Hey%20Kong&limit=5&page=1
        //https://api.a632079.me/nm/search/Skrillex?type=ARTIST&offset=0&limit=30
        //https://api.a632079.me/nm/search/Friend?type=ALBUM&offset=0&limit=30
    
    func downloadSongJSON(url: String, completion: @escaping (_ data: Song?, _ error: Error?) -> Void) {
        print(url)
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Song.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadSongDetailJSON(url: String, completion: @escaping (_ data: SongDetail?, _ error: Error?) -> Void) {
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(SongDetail.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadLyricJSON(url: String, completion: @escaping (_ data: Lyric?, _ error: Error?) -> Void) {
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Lyric.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadPlayListJSON(url: String, completion: @escaping (_ data: Playlist?, _ error: Error?) -> Void) {
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Playlist.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadSearchJSON(url: String, completion: @escaping (_ data: Search?, _ error: Error?) -> Void) {
       guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Search.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadSearchAlbumJSON(url: String, completion: @escaping (_ data: Search?, _ error: Error?) -> Void) {
       guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Search.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadSearchArtistJSON(url: String, completion: @escaping (_ data: SearchArtist?, _ error: Error?) -> Void) {
       guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(SearchArtist.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }
    
    func downloadArtistTracksJSON(url: String, completion: @escaping (_ data: [SongInfo]?, _ error: Error?) -> Void) {
       guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url){ (data, response, err) in
            if err == nil {
                guard let jsondata = data else { return }
                do {
                    let results = try JSONDecoder().decode(Search.self, from: jsondata)
                    DispatchQueue.main.async {
                        completion(results.hotSongs, nil)
                    }
                }catch {
                    print("JSON Downloading Error!")
                }
            }
        }.resume()
    }

}
