//
//  RLTUser.swift
//  RealTimeAVChat
//
//  Created by Karan on 31/08/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import Foundation

class RLTUser:NSObject{
    
    static var shared = RLTUser()
    
    var name:String?
    var email:String?
    var isOnline:Bool?
    var userId:String?
    
    override init() {
        
    }
    
    init(name:String,email:String,online:Bool,id:String) {
        self.name = name
        self.email = email
        self.isOnline = online
        self.userId = id
    }
    
    func getJSON()->[String:Any]{
        var dictionary = [String:Any]()
        dictionary["name"] = self.name ?? ""
        dictionary["email"] = self.email ?? ""
        dictionary["isOnline"] = self.isOnline ?? false
        dictionary["userId"] = self.userId ?? ""
        return dictionary
    }
}
