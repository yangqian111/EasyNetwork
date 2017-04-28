//
//  SignInResponseMapper.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

final class SignInResponseMapper: ResponseMapper<SignInItem>, ResponseMapperProtocol {
    
    static func process(_ obj: AnyObject?) throws -> SignInItem {
        return try process(obj, parse: { json in
            let userName = json["userName"] as? String
            let password = json["password"] as? String
            if let userName = userName, let password = password {
                return SignInItem(userName: userName, password: password)
            }
            return nil
        })
    }
}
