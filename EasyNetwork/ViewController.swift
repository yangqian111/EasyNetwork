//
//  ViewController.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let signInOperation = SignInOperation(userName: "userName", password: "password")
        signInOperation.success = { item in print("User id is \(item.userName)") }
        signInOperation.failure = { error in print(error.localizedDescription) }
        NetworkQueue.shared.addOperation(signInOperation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}

