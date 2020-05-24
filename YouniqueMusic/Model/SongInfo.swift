//
//  SongInfo.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import Foundation

// Song Json
struct SongData: Decodable {
    let id: Int?
    let url: String?
    let br: Int?
    let type: String?
    private enum CodingKeys: String, CodingKey{
        case id, url, br, type
    }
    
}

struct Song : Decodable {
    var data: [SongData]
}

// Lyric Json
struct Lyric: Decodable {
    let lrc: LycData?
}

struct LycData: Decodable {
    let version: Int?
    let lyric: String?
    private enum CodingKeys: String, CodingKey{
        case version, lyric
    }
}

// Detail Json
struct SongDetail: Decodable {
    let songs: [SongInfo]?
}

struct SongInfo: Decodable {
    var timestamp: String?
    let name: String?
    let id: Int?
    let ar: [Artist]?
    let al: Album?
    var liked: Bool?
    private enum CodingKeys: String, CodingKey{
        case name, id, ar, al, liked, timestamp
    }
    init(name: String?, id: Int?, ar: [Artist], al: Album?, liked: Bool?, timestamp: String?) {
        self.name = name
        self.id = id
        self.ar = ar
        self.al = al
        self.liked = false
        self.timestamp = timestamp
    }

}

struct Artist: Decodable {
    let id: Int?
    let name: String?
    private enum CodingKeys: String, CodingKey{
        case name, id
    }
    
    init(id: Int?, name: String?) {
        self.id = id
        self.name = name
    }
}

struct Album: Decodable {
    let id: Int?
    let name: String?
    let picUrl: String?
    let pic_str: String?
    let pic: Int?
    
    init(id: Int?, name: String?, picUrl: String?, pic_str: String?, pic: Int?) {
        self.id = id
        self.name = name
        self.pic_str = pic_str
        self.pic = pic
        self.picUrl = picUrl
    }
}


// Playlist Json

struct Playlist: Decodable {
    let playlist: PlaylistDetail?
    private enum CodingKeys: String, CodingKey{
        case playlist
    }
    
}
struct PlaylistDetail: Decodable {
    let creator: User?
    var tracks: [SongInfo]?
    let tags: [String]?
    let userId: Int?
    let description: String?
    let createTime: Int?
    let updateTime: Int?
    let trackCount: Int?
    let playCount: Int?
    let coverImgUrl: String?
    let name: String?
    let id: Int?
    let shareCount: Int?
    let pid: String?
    let hotSongs: [SongInfo]?
    
    private enum CodingKeys: String, CodingKey{
        case id, name, tags, userId, creator, tracks, description, createTime, updateTime, trackCount, playCount, coverImgUrl, shareCount, pid, hotSongs
    }
    
    init(dict: [String: AnyObject], tracks: [SongInfo]?) {
        creator = dict["creator"] as? User
        self.tracks = tracks
        tags = dict["tags"] as? [String]
        userId = dict["uid"] as? Int
        description = dict["description"] as? String
        createTime = dict["timestamp"] as? Int
        updateTime = dict["updateTime"] as? Int
        trackCount = dict["trackCount"] as? Int
        playCount = dict["playCount"] as? Int
        coverImgUrl = dict["coverImgUrl"] as? String
        name = dict["name"] as? String
        id = dict["id"] as? Int
        shareCount = dict["shareCount"] as? Int
        pid = dict["id"] as? String
        hotSongs = tracks
    }
    
    init(playlist: PlaylistInfo?) {
        creator = nil
        self.tracks = playlist?.tracks
        tags = []
        userId = -1
        description = ""
        createTime = Int(playlist?.timestamp ?? "0")
        updateTime = -1
        trackCount = 0
        playCount = 0
        coverImgUrl = playlist?.profileURL
        name = playlist?.name
        id = -1
        shareCount = 0
        pid = playlist?.id
        hotSongs = playlist?.tracks
    }

}

struct User: Decodable {
    let avatarUrl: String?
    let gender: Int?
    let userId: Int?
    let nickname: String?
    let signature: String?
    private enum CodingKeys: String, CodingKey{
        case avatarUrl, gender, userId, nickname, signature
    }
}

enum SearchType {
    case artist
    case song
}

struct SearchHistory {
    var type: String?
    var name: String?
    var picUrl: String?
    var id: String?
    var timestamp: String?
    var sid: String?
    var track: SongInfo?
    init(dict: [String: AnyObject]) {
        type =  dict["type"] as? String
        name =  dict["name"] as? String
        picUrl =  dict["picURL"] as? String
        id =  dict["id"] as? String
        timestamp =  dict["timestamp"] as? String
        sid =  dict["sid"] as? String
        track = dict["track"] as? SongInfo
    }
}

// Search Json
struct Search: Decodable {
    let songList: [SearchInfo]?
    let hotSongs: [SongInfo]?
    private enum CodingKeys: String, CodingKey{
        case songList, hotSongs
    }
}

struct SearchInfo: Decodable {
    let album: AlbumInfo?
    let artists: [Artist]?
    let name: String?
    let id: Int?
    private enum CodingKeys: String, CodingKey{
        case album, artists, name, id
    }
}

struct AlbumInfo: Decodable {
    let id: Int?
    let name: String?
    let cover: String?
    let coverBig: String?
    let coverSmall: String?
    private enum CodingKeys: String, CodingKey{
        case name, id, cover, coverBig, coverSmall
    }
}

// search artist
struct SearchArtist: Decodable {
    let result: SearchArtistInfo?
}

struct SearchArtistInfo: Decodable {
    let artistCount: Int?
    let artists: [SearchListArtistInfo]?
}

struct SearchListArtistInfo: Decodable {
    let id: Int?
    let name: String?
    let picUrl: String?
    let alias: [String]?
    let img1v1Url: String? //picUrl larger than img1v1Url and picUrl sometime is null but img1v1Url has a defult pic
}

// search album
struct SearchAlbum: Decodable {
    let result: SearchAlbumInfo?
    let code: Int?
}

struct SearchAlbumInfo: Decodable {
    let albumCount: Int?
    let albums: [SearchListAlbumInfo]?
}

struct SearchListAlbumInfo: Decodable {
    let id: Int?
    let name: String?
    let picUrl: String?
    let artist: SearchListArtistInfo?
}

struct LyricInfo: Decodable {
    let lrc: LyricConent?
}

struct LyricConent: Decodable {
    let lrcText: String?
}
