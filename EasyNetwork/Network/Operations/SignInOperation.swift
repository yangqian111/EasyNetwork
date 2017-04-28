//
//  SignInOperation.swift
//  EasyNetwork
//
//  Created by ppsheep on 2017/4/28.
//  Copyright © 2017年 ppsheep. All rights reserved.
//

import Foundation

public class SignInOperation: ServiceOperation {
    
    private let request: SignInRequest
    
    public var success: ((SignInItem) -> Void)?
    public var failure: ((NSError) -> Void)?
    
    public init(userName: String, password: String) {
        request = SignInRequest(userName: userName, password: password)
        super.init()
    }
    
    public override func start() {
        super.start()
        service.request(request, success: handleSuccess, failure: handleFailure)
    }
    
    private func handleSuccess(_ response: AnyObject?) {
        do {
            let item = try SignInResponseMapper.process(response)
            self.success?(item)
            self.finish()
        } catch {
            handleFailure(NSError.cannotParseResponse())
        }
    }
    
    private func handleFailure(_ error: NSError) {
        self.failure?(error)
        self.finish()
    }
}
