//
//  PlayListCell.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//

import Foundation
import UIKit


class PlayCell : UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 80, y: 20, width: UIScreen.main.bounds.width - 160, height: 20)
        //        textLabel?.numberOfLines = 0
        //        textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        detailTextLabel?.frame = CGRect(x: 80, y: 40, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
        
        //        imageView?.frame = CGRect(x: 0, y: 0, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height + textLabel!.frame.height)
        //        imageView?.translatesAutoresizingMaskIntoConstraints = false
        //        imageView?.layer.cornerRadius = 24
        //        imageView?.layer.masksToBounds = true
        //        imageView?.contentMode = .scaleAspectFill
    }
    
    //    let posterImageView: UIImageView = {
    //        let imageView = UIImageView()
    //        imageView.translatesAutoresizingMaskIntoConstraints = false
    //        imageView.layer.cornerRadius = 24
    //        imageView.layer.masksToBounds = true
    //        imageView.contentMode = .scaleAspectFill
    //        return imageView
    //    }()
    //
    //    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    //        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    //        addSubview(posterImageView)
    //
    //        posterImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
    //        posterImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    //        posterImageView.widthAnchor.constraint(equalToConstant: 92).isActive = true
    //        posterImageView.heightAnchor.constraint(equalToConstant: 138).isActive = true
    //
    //    }
    //
    //    required init?(coder aDecoder: NSCoder) {
    //        super.init(coder: aDecoder)
    //        fatalError("init(coder:) has not been implemented")
    //    }
}

class PlayListCell : UITableViewCell {
    
    @IBOutlet var trackImage: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var moreInfoImage: UIImageView!
    var idString: String?
    
    func downloadImageUsingCacheWithLink(_ urlLink: String, view: UITableView) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let cachedImage = appDelegate.imageCache.object(forKey: urlLink as NSString) {
            if idString == urlLink {
                self.trackImage.image = cachedImage
            }
            return
        }
        guard let url = URL(string: urlLink) else { return }
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let err = error {
                print(err)
                return
            }
            DispatchQueue.main.async {
                if let newImage = UIImage(data: data!) {
                    appDelegate.imageCache.setObject(newImage, forKey: urlLink as NSString)
                    if self.idString == urlLink {
                        self.trackImage.image = newImage
                    }
                    
                    view.reloadData()
                    
                }
            }
        }).resume()
    }
}

//class SearchListCell : UITableViewCell {
//    
//    @IBOutlet var trackImage: UIImageView!
//    @IBOutlet var songNameLabel: UILabel!
//    @IBOutlet var artistLabel: UILabel!
//    @IBOutlet var moreInfoImage: UIImageView!
//}

