//
//  NetworkService.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

class NetworkService {
    
    private var task: URLSessionDataTask?
    private var successCodes: CountableRange<Int> = 200..<299//成功的code
    private var failureCodes: CountableRange<Int> = 400..<499//错误的code
    
    ///HTTP METHOD
    enum Method: String {
        case get, post, put, delete
    }
    
    enum QueryType {
        case json, path
    }
    
    func makeRequest(for url: URL, method: Method, queryType: QueryType,
                     params: [String : Any]? = nil,
                     headers: [String : String]? = nil,
                     success: ((Data?) -> Void)? = nil,
                     failure: ((_ data: Data?, _ error: NSError?, _ responseCode: Int) -> Void)? = nil) {
        var mutableRequest = makeQuery(for: url, params: params, type: queryType)
        
        mutableRequest.allHTTPHeaderFields = headers
        mutableRequest.httpMethod = method.rawValue
        
        let session = URLSession.shared
        
        task = session.dataTask(with: mutableRequest, completionHandler: { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else {
                failure?(data, error as NSError?, 0)
                return
            }
            
            if let error = error {
                failure?(data, error as NSError?, 0)
                return
            }
            
            if self.successCodes.contains(httpResponse.statusCode) {
                success?(data)
            } else if self.failureCodes.contains(httpResponse.statusCode) {
                failure?(data, error as NSError?, httpResponse.statusCode)
            } else {
                let info = [
                    NSLocalizedDescriptionKey: "Request failed with code \(httpResponse.statusCode)",
                    NSLocalizedFailureReasonErrorKey: "Wrong handling logic, wrong endpoing mapping or EasyNetwork bug."
                ]
                let error = NSError(domain: "NetworkService", code: 0, userInfo: info)
                failure?(data, error, httpResponse.statusCode)
            }
        })
        
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
    
    /// 创建request对象
    private func makeQuery(for url: URL, params: [String : Any]?, type: QueryType) -> URLRequest {
        switch type {
        /// 通过httpBody传参
        case .json:
            var mutableRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
            if let params = params {
                mutableRequest.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
            }
            return mutableRequest
        /// URL 尾部带上参数
        case .path:
            var query = ""
            params?.forEach({ (key, value) in
                query = query + "\(key)=\(value)&"
            })
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.query = query
            return URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        }
    }
    
}
