//
//  HostConfiguration.swift
//  EasyNetwork
//  存储baseURL
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

public final class HostConfiguration {

    let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    public static var shared: HostConfiguration!
    
    class func baseURL(_ urlString: String) {
        let url = URL(string: urlString)!
        HostConfiguration.shared = HostConfiguration(baseURL: url)
    }
}
