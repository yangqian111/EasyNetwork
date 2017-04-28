//
//  EasyNetworkService.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

public let DidPerformUnauthorizedOperation = "DidPerformUnauthorizedOperation"

import Foundation

class EasyNetworkService {
    
    private let conf: HostConfiguration //
    private let service = NetworkService()//发请求的网络服务类
    
    init(_ conf: HostConfiguration) {
        self.conf = conf
    }
    
    func request(_ request: BaseAPIRequest,
                 success: ((AnyObject?) -> Void)? = nil,
                 failure: ((NSError) -> Void)? = nil) {
        
         let url = conf.baseURL.appendingPathComponent(request.api)
        
        let headers = request.headers
        
        service.makeRequest(for: url, method: request.method, queryType: request.query, params: request.params, headers: headers, success: { data in
            var json: AnyObject? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data as Data, options: []) as AnyObject
            }
            success?(json)
        }, failure: { data, error, statusCode in
            if statusCode == 401 {
                // Operation not authorized
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: DidPerformUnauthorizedOperation), object: nil)
                return
            }
            
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data as Data, options: []) as AnyObject
                let info = [
                    NSLocalizedDescriptionKey: json?["error"] as? String ?? "",
                    NSLocalizedFailureReasonErrorKey: "Probably not allowed action."
                ]
                let error = NSError(domain: "EasyNetworkService", code: 0, userInfo: info)
                failure?(error)
            } else {
                failure?(error ?? NSError(domain: "EasyNetworkService", code: 0, userInfo: nil))
            }
        })
        
    }
    
    func cancle() {
        service.cancel()
    }
}
