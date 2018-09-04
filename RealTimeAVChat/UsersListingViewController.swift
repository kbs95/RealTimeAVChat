//
//  UsersListingViewController.swift
//  RealTimeAVChat
//
//  Created by Karan on 31/08/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CallKit
import OpenTok

class UsersListingViewController: UIViewController,CallRecievedDelegate,CallEndedDelegate {

    lazy var tableView:UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        return tableView
    }()
    
    var listOfUsers:[RLTUser] = []
    var callProvider:CXProvider!
    var tokSesionController:TokSessionViewController!
    
    let cellIdentifier = "UserCell"
    let callerUUID = UUID()
    var callerName:String = ""
    var callerId:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateUserDetails()
        initialSetup()
        fetchUsersFromDB()
        createCallProvider()
        callHistoryListener()
        //NotificationCenter.default.addObserver(self, selector: #selector(startListeningTokSessionDelegates), name: NSNotification.Name(rawValue: "startSession"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        callerName = ""
        startListeningTokSessionDelegates()
    }
    
    func createCallProvider(){
        let config = CXProviderConfiguration(localizedName: "")
        config.supportsVideo = true
        config.includesCallsInRecents = false
        callProvider = CXProvider(configuration: config)
        callProvider.setDelegate(self, queue: DispatchQueue.main)
    }
    
    @objc func startListeningTokSessionDelegates(){
        tokSesionController = TokSessionViewController()
        tokSesionController.callRecieveDelegate = self
        tokSesionController.callEndDelegate = self
        tokSesionController.createNewTokSession()
    }
    
    func callRecieved(forStream:OTStream) {
        // recieve call here
        tokSesionController.isReciever = true
        tokSesionController.isCaller = false
        tokSesionController.callStream = forStream
        recieveCall()
    }
    
    func callEnded() {
        let callController = CXCallController()
        let endCallAction = CXEndCallAction(call: callerUUID)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let _ = error {
                self.callProvider.reportCall(with: self.callerUUID, endedAt: Date(), reason: .remoteEnded)
                return
            }
            print("EndCallAction transaction request successful")
        }
    }
    
    func recieveCall(){
        if callerName.isEmpty{
            tokSesionController.isReciever = false
            tokSesionController.isCaller = false
            tokSesionController.callStream = nil
            tokSesionController.createNewTokSession()
            return
        }
        let callUpdater = CXCallUpdate()
        callUpdater.hasVideo = true
        callUpdater.remoteHandle = CXHandle(type: .generic, value: callerName + " Calling...")
        callProvider.reportNewIncomingCall(with: callerUUID, update: callUpdater) { (err) in
            if err != nil{
                self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
            }
        }
    }
    
    func populateUserDetails(){
        guard let uId = Auth.auth().currentUser?.uid else{
            return
        }
        Database.database().reference().child("RLTUser").child(uId).observe(DataEventType.value) { (snapshot) in
            let dictionary = snapshot.value as? [String:Any] ?? [:]
            RLTUser.shared.email = dictionary["email"] as? String ?? ""
            RLTUser.shared.name = dictionary["name"] as? String ?? ""
            RLTUser.shared.isOnline = dictionary["isOnline"] as? Bool ?? false
            RLTUser.shared.userId = dictionary["userId"] as? String ?? ""
            self.title = "Welcome \(RLTUser.shared.name ?? "")"
        }
    }

    
    func fetchUsersFromDB(){
        SpinnerView.shared.showSpinnerOn(view: self.tableView)
        Database.database().reference().child("RLTUser").observe(DataEventType.value) { (dataSnapshot) in
            SpinnerView.shared.removeSpinnerFrom(view: self.tableView)
            let dataDictionary = dataSnapshot.value as? [String:Any] ?? [:]
            DispatchQueue.main.async {
                self.updateTableView(usersData:dataDictionary)
            }
        }
    }
    
    func updateTableView(usersData:[String:Any]){
        var indexPathsToUpdate = [IndexPath]()
        listOfUsers = []
        tableView.reloadData()
        for (_,keyValue) in usersData.enumerated(){
            // do not add current user
            if Auth.auth().currentUser?.uid == keyValue.key{
                continue
            }
            let value = keyValue.value as? [String:Any] ?? [:]
            let userObj = RLTUser(name: value["name"] as? String ?? "", email: value["email"] as? String ?? "",online : value["isOnline"] as? Bool ?? false,id:keyValue.key)
            (userObj.isOnline ?? false) ? self.listOfUsers.insert(userObj, at: 0) : self.listOfUsers.append(userObj)
            indexPathsToUpdate.append(IndexPath(row: listOfUsers.count - 1, section: 0))
        }
        tableView.beginUpdates()
        tableView.insertRows(at: indexPathsToUpdate, with: .fade)
        tableView.endUpdates()
    }
    
    func initialSetup(){
        self.title = "Welcome \(RLTUser.shared.name ?? "")"
        self.navigationController?.navigationBar.barTintColor = UIColor(red:0.61, green:0.65, blue:1.00, alpha:1.0)
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        // logout button
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icons8-exit-50"), style: .plain, target: self, action: #selector(logoutAction))
    }

    @objc func logoutAction(){
        do{
            setStatusForCurrentUser(isOnline: false)
            try Auth.auth().signOut()
        }catch let err{
            self.showAlert(title: "Error", message: err.localizedDescription)
            setStatusForCurrentUser(isOnline: true)
            return
        }
        if self.navigationController?.presentingViewController != nil{
            self.navigationController?.dismiss(animated: true, completion: nil)
        }else{
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewControllerIdentifier")
            UIApplication.shared.keyWindow?.rootViewController = loginVC
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func callUser(sender:UIButton){
        let userToCall = listOfUsers[sender.tag]
        if userToCall.isOnline ?? false{
            createCallHistory(user: userToCall)
        }else{
            self.showAlert(title: "Can't make a call", message: "\(userToCall.name ?? "User") is offline")
        }
    }
    
    func createCallHistory(user:RLTUser){
        let historyRef = Database.database().reference().child("CallHistory").child(Auth.auth().currentUser?.uid ?? "")
        var historyData:[String:Any] = [:]
        historyData["callerName"] = RLTUser.shared.name ?? ""
        historyData["recieverId"] = user.userId ?? ""
        historyRef.updateChildValues(historyData) { (err, ref) in
            if err == nil{
                // make call
                self.tokSesionController.isCaller = true
                self.tokSesionController.callStream = nil
                self.present(self.tokSesionController, animated: true, completion: nil)
            }else{
                self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
            }
        }
    }
    
    func deleteCallHistory(){
        if callerId == ""{
            return
        }
        let historyRef = Database.database().reference().child("CallHistory").child(callerId)
        historyRef.removeValue { (err, ref) in
            if err == nil{
                self.callerName = ""
                self.callerId = ""
            }else{
               self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
            }
        }
    }
    
    func callHistoryListener(){
        let historyRef = Database.database().reference().child("CallHistory")
        historyRef.observe(DataEventType.value) { (snapshot) in
            let dt = snapshot.value as? [String:Any] ?? [:]
            dt.forEach({ (keyValue) in
                let data = keyValue.value as? [String:Any] ?? [:]
                if (data["recieverId"] as? String ?? "") == RLTUser.shared.userId{
                    self.callerName = data["callerName"] as? String ?? ""
                    self.callerId = keyValue.key
                }
            })
        }
        
        historyRef.observe(DataEventType.childRemoved) { (snapshot) in
            // end ongoing call
            let value = snapshot.value as? [String:Any] ?? [:]
            for keyVal in value{
                if RLTUser.shared.userId == snapshot.key || RLTUser.shared.userId == ((keyVal.value as? [String:Any] ?? [:])["recieverId"] as? String ?? ""){
                    self.tokSesionController.disconnectSession()
                    self.startListeningTokSessionDelegates()
                }
            }
        }
    }
}

extension UsersListingViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! UsersTableViewCell
        cell.selectionStyle = .none
        cell.userNameLabel.text = listOfUsers[indexPath.row].name ?? ""
        (listOfUsers[indexPath.row].isOnline ?? false) ? (cell.onlineView.backgroundColor = .green) : (cell.onlineView.backgroundColor = .lightGray)
        cell.chatButton.tag = indexPath.row
        cell.chatButton.addTarget(self, action: #selector(callUser(sender:)), for: .touchUpInside)
        return cell
    }
}

// call provider delegates

extension UsersListingViewController:CXProviderDelegate{
    func providerDidReset(_ provider: CXProvider) {
        print("provider reset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("user answered")
        action.fulfill()
        self.present(tokSesionController, animated: true, completion: nil)
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("user rejected")
        action.fulfill()
        tokSesionController.isReciever = false
        tokSesionController.isCaller = false
        tokSesionController.callStream = nil
        startListeningTokSessionDelegates()
        callerName = ""
        deleteCallHistory()
    }
}

