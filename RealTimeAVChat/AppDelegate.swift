//
//  AppDelegate.swift
//  RealTimeAVChat
//
//  Created by Karan on 31/08/18.
//  Copyright © 2018 Karan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        if let _ = UserDefaults.standard.value(forKey: "firstRun") as? Bool{
        }else{
            do{
                try Auth.auth().signOut()
                UserDefaults.standard.set(true, forKey: "firstRun")
            }catch let err{
                print(err)
            }
        }
        checkIfUserIsLoggedIn()
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        setStatusForCurrentUser(isOnline: false)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        setStatusForCurrentUser(isOnline: true)
        if Auth.auth().currentUser?.uid != nil{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "startSession"), object: nil)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        setStatusForCurrentUser(isOnline: false)
    }

    func checkIfUserIsLoggedIn(){
        window = UIWindow()
        if Auth.auth().currentUser?.uid == nil{
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewControllerIdentifier")
            window?.rootViewController = loginVC
        }else{
            setStatusForCurrentUser(isOnline: true)
            window?.rootViewController = UINavigationController(rootViewController: UsersListingViewController())
        }
        window?.makeKeyAndVisible()
    }
}

