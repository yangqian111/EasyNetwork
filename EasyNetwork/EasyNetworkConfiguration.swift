//
//  EasyNetworkConfiguration.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

class EasyNetworkConfiguration {
    
    class func setUp() {
        let url = URL(string: "")!
        let conf = HostConfiguration(baseURL: url)
        HostConfiguration.shared = conf
        
        NetworkQueue.shared = NetworkQueue()
    }
    
}
