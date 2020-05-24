//
//  RecommendCell.swift
//  YouniqueMusic
//
//  Created by xww on 3/18/20.
//  Copyright © 2020 Wanxiang Xie. All rights reserved.
//
import Foundation
import UIKit

class RecommendCell: UICollectionViewCell {
    
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var coverImage: UIImageView!
    @IBOutlet var playImage: UIImageView!
    var songID: Int?
    var idString: String?
    
    func downloadImageUsingCacheWithLink(_ urlLink: String, view: UICollectionView) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let cachedImage = appDelegate.imageCache.object(forKey: urlLink as NSString) {
            if idString == urlLink {
                self.coverImage.image = cachedImage
            }
            
            
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
                    appDelegate.imageCache.setObject(newImage, forKey: urlLink as NSString)
                    if self.idString == urlLink {
                                   self.coverImage.image = newImage
                               }
                    
                    view.reloadData()
                    
                }
            }
        }).resume()
    }
}
