//
//  ServiceOperation.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

public class ServiceOperation: NetworkOperation {
    
    let service: EasyNetworkService
    
    public override init() {
        self.service = EasyNetworkService(HostConfiguration.shared)
        super.init()
    }
    
    public override func cancel() {
        service.cancle()
        super.cancel()
    }
}
