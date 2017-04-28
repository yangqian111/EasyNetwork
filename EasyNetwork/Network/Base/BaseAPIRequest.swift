//
//  BaseAPIRequest.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

protocol BaseAPIRequest {
    var api: String { get }
    var method: NetworkService.Method { get }
    var query: NetworkService.QueryType { get }
    var params: [String : Any]? { get }
    var headers: [String : String]? { get }
}


extension BaseAPIRequest {
    
    ///默认返回json
    func defaultJsonHeader() -> [String : String] {
        return ["Content-Type" : "application/json"]
    }
}
