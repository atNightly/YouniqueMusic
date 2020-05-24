//
//  CommentList.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

class CommentList {
    var commentList : [Comment] = []
    
    func remove(key: String) -> Int {
        var index = 0
        for comment in commentList {
            
            if key == comment.id {
                commentList.remove(at: index)
                return index
            }
            index += 1
        }
        return -1
    }
    func removeAll() {
        commentList = []
    }
    
    func append(comment: Comment) {
        commentList.append(comment)
    }
    
    func update(commentItem: Comment) {
        var index = -1
        var isFind = false
        for comment in commentList {
            index += 1
            if commentItem.id == comment.id {
                isFind = true
                break
            }
        }
        if isFind {
            commentList[index] = commentItem
        }
    }
}
