//
//  TokSessionViewController.swift
//  RealTimeAVChat
//
//  Created by Abhishar Jangir on 01/09/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import UIKit
import OpenTok
import CallKit
import FirebaseDatabase
import FirebaseAuth

protocol CallRecievedDelegate:NSObjectProtocol{
    func callRecieved(forStream:OTStream)
}

protocol CallEndedDelegate:NSObjectProtocol{
    func callEnded()
}


class TokSessionViewController: UIViewController {

    var apiKey:String = "46180522"
    var sessionId:String = ""
    var token:String = ""
    var tokSession:OTSession?
    lazy var tokPublisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    var tokSubscriber:OTSubscriber?
    lazy var endCallButton:UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "icons8-delete-64"), for: .normal)
        button.addTarget(self, action: #selector(disconnectSession), for: .touchUpInside)
        return button
    }()
    var publisherViewConstraints:[NSLayoutConstraint] = []
    var callRecieveDelegate:CallRecievedDelegate?
    var callEndDelegate:CallEndedDelegate?
    var isReciever:Bool = false
    var callStream:OTStream!
    var callerData:RLTUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        SpinnerView.shared.showSpinnerOn(view: view)
        createNewTokSession()
    }
    
    func createNewTokSession(){
        // reciever session
        if !sessionId.isEmpty{
            self.tokSession = OTSession(apiKey: self.apiKey, sessionId: sessionId, delegate: self)
            var sessionError:OTError?
            self.tokSession?.connect(withToken: token, error: &sessionError)
            if sessionError == nil{
                return
            }
            self.showAlert(title: "Error", message: sessionError?.localizedDescription ?? "")
            return
        }
        SessionGenerator.shared.getSessionDataFromHeroku(completion: { (sessionId, token) in
            self.sessionId = sessionId
            self.token = token
            self.tokSession = OTSession(apiKey: self.apiKey, sessionId: sessionId, delegate: self)
            var sessionError:OTError?
            self.tokSession?.connect(withToken: token, error: &sessionError)
            if sessionError == nil{
                return
            }
            self.showAlert(title: "Error", message: sessionError?.localizedDescription ?? "")
        })
    }
    
    func createCallHistory(){
        let historyRef = Database.database().reference().child("CallHistory").child(Auth.auth().currentUser?.uid ?? "")
        var historyData:[String:Any] = [:]
        historyData["callerName"] = RLTUser.shared.name ?? ""
        historyData["recieverId"] = callerData.userId ?? ""
        historyData["sessionId"] = self.sessionId
        historyData["token"] = self.token
        historyRef.updateChildValues(historyData) { (err, ref) in
            if err == nil{
                // make call
            }else{
                self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
            }
        }
    }
    
    func createNewPublisher(){
        var error:OTError?
        tokPublisher.delegate = self
        tokSession?.publish(tokPublisher, error: &error)
        if error == nil{
            setupPublisherView()
            return
        }
        self.showAlert(title: "Error", message: error?.localizedDescription ?? "")
    }
    
    func createNewSubscriber(forStream:OTStream){
        if let subscriber = OTSubscriber(stream: forStream, delegate: self){
            self.tokSubscriber = subscriber
            var error:OTError?
            tokSession?.subscribe(subscriber, error: &error)
            if error == nil{
                setupSubscriberView()
                return
            }
            self.showAlert(title: "Error", message: error?.localizedDescription ?? "")
        }
    }
    
    func setupSubscriberView(){
        guard let subscriberView = tokSubscriber?.view else{
            return
        }
        subscriberView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subscriberView)
        subscriberView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        subscriberView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        subscriberView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        subscriberView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.bringSubview(toFront: endCallButton)
        
        // animate publisherView to bottom
        publisherViewConstraints[0].constant = view.frame.height * 0.7
        publisherViewConstraints[1].constant = -10
        publisherViewConstraints[2].constant = 10
        publisherViewConstraints[3].constant = -(view.frame.width * 0.65)
        view.bringSubview(toFront: (tokPublisher.view)!)
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func setupPublisherView(){
        guard let publisherView = tokPublisher.view else{
            return
        }
        publisherView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(publisherView)
        publisherViewConstraints.append(publisherView.topAnchor.constraint(equalTo: view.topAnchor))
        publisherViewConstraints.append(publisherView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        publisherViewConstraints.append(publisherView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        publisherViewConstraints.append(publisherView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        publisherView.layer.shadowOffset = CGSize(width: 1, height: 1)
        publisherView.layer.shadowRadius = 4
        publisherView.layer.shadowOpacity = 0.75
        
        publisherViewConstraints.forEach { (constraint) in
            constraint.isActive = true
        }
        
        view.bringSubview(toFront: endCallButton)
    }
    
    func setupViews(){
        view.addSubview(endCallButton)
        endCallButton.widthAnchor.constraint(equalToConstant: 62).isActive = true
        endCallButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        endCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        endCallButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
    }
    
    @objc func disconnectSession(){
        tokPublisher.view?.removeFromSuperview()
        tokSubscriber?.view?.removeFromSuperview()
        if tokSession != nil{
            var error:OTError?
            tokSession?.disconnect(&error)
        }
        self.dismiss(animated: true, completion: nil)
//        callEndDelegate?.callEnded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension TokSessionViewController:OTSessionDelegate{
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        SpinnerView.shared.removeSpinnerFrom(view: view)
        createNewPublisher()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("Session failed with \(error.localizedDescription)")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("stream created")
        createNewSubscriber(forStream: stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("stream destroyed")
        disconnectSession()
    }
}

extension TokSessionViewController:OTPublisherDelegate{
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("publishing failed with \(error.localizedDescription)")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("publisher created stream")
        if !isReciever{
            createCallHistory()
        }
    }
}

extension TokSessionViewController:OTSubscriberDelegate{
    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        print("subscriber Did connect")
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("subscriber failed with \(error.localizedDescription)")
    }
    
    
}
