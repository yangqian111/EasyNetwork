//
//  NetworkQueue.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

public class NetworkQueue {
    
    public static var shared = NetworkQueue()
    
    let queue = OperationQueue()
    
    public func addOperation(_ op: Operation) {
        queue.addOperation(op)
    }
}
