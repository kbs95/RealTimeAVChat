//
//  UsersTableViewCell.swift
//  RealTimeAVChat
//
//  Created by Karan on 31/08/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import UIKit

class UsersTableViewCell: UITableViewCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var onlineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        onlineView.layer.cornerRadius = onlineView.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
