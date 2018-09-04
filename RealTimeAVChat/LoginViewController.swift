//
//  ViewController.swift
//  RealTimeAVChat
//
//  Created by Karan on 31/08/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var signUpView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwrdLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameFieldLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mailFieldCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordBottomConstraint: NSLayoutConstraint!
    
    var dbReference:DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        segmentControl.addTarget(self, action: #selector(segmentChanged(segment:)), for: .valueChanged)
    }
    
    func initialSetup(){
        signUpView.layer.cornerRadius = 8
        signUpView.layer.shadowOffset = CGSize(width: 0, height: 1)
        signUpView.layer.shadowRadius = 3
        signUpView.layer.shadowOpacity = 0.6
        signUpButton.layer.cornerRadius = 8
        activityIndicator.alpha = 0
        nameFieldLeadingConstraint.constant = UIScreen.main.bounds.width
        emailLeadingConstraint.constant = UIScreen.main.bounds.width
        emailTextField.keyboardType = .emailAddress
        passwrdLeadingConstraint.constant = UIScreen.main.bounds.width
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        dbReference = Database.database().reference(fromURL: "https://realtimeavchat.firebaseio.com/")
    }
    
    @objc func segmentChanged(segment:UISegmentedControl){
        emailTextField.text = ""
        nameTextField.text = ""
        passwordTextField.text = ""
        
        if segmentControl.selectedSegmentIndex == 0{
            // signup
            mailFieldCenterConstraint.constant = -20
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseIn, animations: {
                self.nameTextField.alpha = 1
                self.view.layoutIfNeeded()
            }) { (succ) in
            }
            signUpButton.setTitle(RegisterButtonTitles.signUp.rawValue, for: .normal)
        }else{
            // login
            mailFieldCenterConstraint.constant = -50
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseIn, animations: {
                self.nameTextField.alpha = 0
                self.view.layoutIfNeeded()
            }) { (succ) in
            }
            signUpButton.setTitle(RegisterButtonTitles.login.rawValue, for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.6) {
            self.animateFields()
        }
    }
    
    func animateFields(){
        nameFieldLeadingConstraint.constant = 20
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (succ) in
            self.emailLeadingConstraint.constant = 20
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            }) { (succ) in
                self.passwrdLeadingConstraint.constant = 20
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
                    self.view.layoutIfNeeded()
                }) { (succ) in
                }
            }
        }
    }
    
    @IBAction func signupButtonAction(_ sender: UIButton) {
        if signUpButton.titleLabel?.text == RegisterButtonTitles.signUp.rawValue{
            guard let name = nameTextField.text,let email = emailTextField.text,let password = passwordTextField.text,name != "",email != "",password != "" else{
                self.showAlert(title: "Error", message: "Please fill all the fields.")
                return
            }
            self.firebaseService(inProgress: true)
            Auth.auth().createUser(withEmail: email, password: password) { (user, err) in
                if err == nil{
                    if let userData = user{
                        self.createUserInFIRDB(user: userData)
                    }
                }else{
                    self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
                    self.firebaseService(inProgress: false)
                }
            }
            // signup new user
        }else{
            // login old user
            guard let email = emailTextField.text,let password = passwordTextField.text,email != "",password != "" else{
                self.showAlert(title: "Error", message: "Please fill all the fields.")
                return
            }
            self.firebaseService(inProgress: true)
            Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
                if err == nil{
                    setStatusForCurrentUser(isOnline: true)
                    self.navigateToUserListing()
                }else{
                    self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
                }
                self.firebaseService(inProgress: false)
            }
        }
    }
    
    
    func createUserInFIRDB(user:User){
        let childReference = dbReference.child("RLTUser").child(user.uid)
        let userObj = RLTUser(name: nameTextField.text ?? "", email: user.email ?? "",online:true,id:user.uid)
        childReference.updateChildValues(userObj.getJSON()) { (err, reference) in
            if err == nil{
                print(reference)
                self.navigateToUserListing()
            }else{
                self.showAlert(title: "Error", message: err?.localizedDescription ?? "")
            }
            self.firebaseService(inProgress: false)
        }
    }
    
    func navigateToUserListing(){
        // clear all fields
        emailTextField.text = ""
        nameTextField.text = ""
        passwordTextField.text = ""
        // navigate to user listings
        let navigationController = UINavigationController(rootViewController: UsersListingViewController())
        self.present(navigationController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func firebaseService(inProgress:Bool){
        if inProgress{
            self.signUpButton.alpha = 0
            self.activityIndicator.alpha = 1
            self.activityIndicator.startAnimating()
        }else{
            self.signUpButton.alpha = 1
            self.activityIndicator.alpha = 0
            self.activityIndicator.stopAnimating()
        }
    }

}

extension LoginViewController:UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
