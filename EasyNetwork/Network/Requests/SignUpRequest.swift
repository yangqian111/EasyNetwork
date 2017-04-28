//
//  SignUpRequest.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

final class SignInRequest: BaseAPIRequest {
    
    private let userName: String
    private let password: String
    
    init(userName: String, password: String) {
        self.userName = userName
        self.password = password
    }
    
    
    var method: NetworkService.Method {
        return .post
    }
    
    var query: NetworkService.QueryType {
        return .json
    }
    
    var params: [String : Any]? {
        return [
            "username" : userName,
            "password" : password
        ]
    }
    
    var api: String {
        return "/sign_in"
    }
    
    var headers: [String : String]? {
        return defaultJsonHeader()
    }
}
