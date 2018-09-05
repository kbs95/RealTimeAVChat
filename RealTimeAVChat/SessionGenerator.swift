//
//  SessionGenerator.swift
//  RealTimeAVChat
//
//  Created by Karanbir Singh on 9/4/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import Foundation
import SwiftyJWT

class SessionGenerator{
    static var shared = SessionGenerator()
    
    func getNewJSONWebToken()->String?{
        let alg = JWTAlgorithm.hs256("83cd8524d40b12f6b6904080a77deb3c864ae907")
        var payload = JWTPayload()
        payload.issueAt = Int(Date().timeIntervalSince1970)
        payload.expiration = Int((Date().timeIntervalSince1970) + 300)
        payload.issuer = "46180522"
        let jwtWithKeyId = JWT.init(payload: payload, algorithm: alg)
        return jwtWithKeyId?.rawString
    }
    
    func createSession(completion:@escaping (_ sessionId:String?)->()){
        var urlRequest = URLRequest(url: URL(string:"https://api.opentok.com/session/create?p2p.preference=disabled")!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue(getNewJSONWebToken() ?? "", forHTTPHeaderField: "X-OPENTOK-AUTH")
        URLSession.shared.dataTask(with: urlRequest) { (data, response, err) in
            if err == nil{
                if let jsonData = data{
                    let sessionData = try! JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [[String:Any]] ?? []
                    completion(sessionData[0]["session_id"] as? String)
                }
            }else{
                // err
                completion(nil)
            }
            }.resume()
    }
    
    func getSessionDataFromHeroku(completion: @escaping (_ sessionId:String,_ token:String) -> ()){
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let url = URL(string: "https://realtimeavsession.herokuapp.com/session")
        let dataTask = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil, let data = data else {
                print(error!)
                return
            }
            
            let dict = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any]
            completion(dict?["sessionId"] as? String ?? "",dict?["token"] as? String ?? "")
        }
        dataTask.resume()
        session.finishTasksAndInvalidate()
    }
}
