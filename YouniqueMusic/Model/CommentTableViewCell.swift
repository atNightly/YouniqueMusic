//
//  CommentTableViewCell.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet var editButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var likeImage: UIImageView!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var profileImage: UIImageView!

    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    var idString: String?
}
