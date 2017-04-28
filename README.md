# EasyNetwork
正在维护两个SDK，两个SDK中均需要进行网络请求，但是从业务方了解到，他们不希望每次集成一个SDK，就是集成了一个大的网络库，代码量急剧上升，所以在考虑自己在SDK中封装一套网络库，精简可用，不需要引入第三方的代码，也能够大大缩减SDK的体积

> 本篇文章思路来源于 http://szulctomasz.com/how-do-I-build-a-network-layer/ 非常感谢Tomasz Szulc的分享

我们一步一步来实现这个网络框架，首先，我需要一个request类，来保存我每次请求的参数、请求方法、请求的API等等

### APIRequets

之前看到的很多这种request，都是有一个基类，然后每个request是子类，重写父类的一些方法，这里我是通过协议来实现

##### BaseAPIRequest

```swift
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
```

协议包含了我们普通请求的所需要的参数、请求地址、请求方法、请求类型和请求头，并且还有一个扩展，默认请求类型是json

关于请求方法和请求类型的枚举类型，后面我们会讲到

有一个登录请求request，他实现了BaseAPIRequest

```swift
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
```

这样，我们每个请求的所需要的参数，都封装在了一个request对象当中，接下来要考虑的是怎样发起这个网络请求，最终采取的方案是，通过NSOperation和NSOperationQueue来实现网络请求的发起

这里用到了自定义operation，如果对这一块不太了解的同学，可以看看我之前的一篇文章

http://ppsheep.com/2017/03/14/Operation-Queues并发编程/

### Operation发起网络请求

自定义一个可并发的operation

```swift
import Foundation

public class NetworkOperation: Operation {
    
    private var _isReady: Bool
    
    public override var isReady: Bool {
        get { return _isReady }
        set { update(
            { self._isReady = newValue }, key: "isReady") }
    }
    
    private var _isExecuting: Bool
    public override var isExecuting: Bool {
        get { return _isExecuting }
        set { update({ self._isExecuting = newValue }, key: "isExecuting") }
    }
    
    private var _isFinished: Bool
    public override var isFinished: Bool {
        get { return _isFinished }
        set { update({ self._isFinished = newValue }, key: "isFinished") }
    }
    
    private var _isCancelled: Bool
    public override var isCancelled: Bool {
        get { return _isCancelled }
        set { update({ self._isCancelled = newValue }, key: "isCancelled") }
    }
    
    private func update(_ change: (Void) -> Void, key: String) {
        willChangeValue(forKey: key)
        change()
        didChangeValue(forKey: key)
    }
    
    override init() {
        _isReady = true
        _isExecuting = false
        _isFinished = false
        _isCancelled = false
        super.init()
        name = "Network Operation"
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    public override func start() {
        if self.isExecuting == false {
            self.isReady = false
            self.isExecuting = true
            self.isFinished = false
            self.isCancelled = false
            print("\(self.name!) operation started.")
        }
    }
    
    /// Used only by subclasses. Externally you should use `cancel`.
    func finish() {
        print("\(self.name!) operation finished.")
        self.isExecuting = false
        self.isFinished = true
    }
    
    public override func cancel() {
        print("\(self.name!) operation cancelled.")
        self.isExecuting = false
        self.isCancelled = true
    }
}
```

ServiceOperation是NetworkOperation的一个子类，在其中加入了网络请求入口EasyNetworkService，并且将取消请求的方法定义设置

```swift
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
```

接下来，我每个请求的operation，都继承自ServiceOperation，在每个请求发起的时候，将这个operation添加到队列当中即可

```swift
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
```

在上面的登录请求operation中，有成功的回调和失败的回调，其中还涉及到了将返回的数据转成一个model，后面我们也是会讲到的

operation已经定义好，我们还需要一个operationQueue来执行我们的operation

```swift
import Foundation

public class NetworkQueue {
    
    public static var shared = NetworkQueue()
    
    let queue = OperationQueue()
    
    public func addOperation(_ op: Operation) {
        queue.addOperation(op)
    }
}
```

这样，我们对外需要暴露的接口基本上已经实现完成，现在如果我要发起一次请求，就是这样一种方式

```swift
let signInOperation = SignInOperation(userName: "userName", password: "password")
signInOperation.success = { item in print("User id is \(item.userName)") }
signInOperation.failure = { error in print(error.localizedDescription) }
NetworkQueue.shared.addOperation(signInOperation)
```

好像还缺点什么，好像还没有baseURL的定义，加一个，定义baseURL

```swift
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
```

在我们启动之后，将baseURL设置进去就行

```swift
HostConfiguration.baseURL("http://")//设置baseURL
```

接下来，我们就来实现内部的网络请求，真正的网络请求发送，我们使用的是apple提供的URLSession框架

我们发起网络请求，到达最后的地方，是在operation的start方法中，调用了

```swift
public override func start() {
        super.start()
        service.request(request, success: handleSuccess, failure: handleFailure)
}
```

这个service是一个EasyNetworkService，它内部实现了完整URL的拼接，header的设置，在它内部实现了具体的请求调用

```swift
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

```

在上面的service中，又出现了一个NetworkService，这个service就是组装URLSession，进行网络请求的发出

```swift

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

```

在这个service中，我们将所有的参数都收集起来，发出网络请求，使用的是datatask，当然这只是其中一种方式，可以扩展下载，上传等等网络请求

这样，整个一个网络请求的流程就讲完了，上面我们还讲到了要将返回的参数转成一个model，在调用处，我们实际接收到的是一个struct对象，这个转化的过程，我们放在了operation中

在operation的处理成功请求的时候，有一行代码是这样的

```swift
let item = try SignInResponseMapper.process(response)
```
这其实就是将返回的数据转化成我们需要的model

这里，做了两种映射，一种是单个的json对象，一个是解析一个json对象数组

单个解析：

```swift
import Foundation

protocol ResponseMapperProtocol {
    associatedtype Item
    static func process(_ obj: AnyObject?) throws -> Item
}

internal enum ResponseMapperError: Error {
    case invalid
    case missingAttribute
}

class ResponseMapper<A: ParsedItem> {
    
    static func process(_ obj: AnyObject?, parse: (_ json: [String: AnyObject]) -> A?) throws -> A {
        guard let json = obj as? [String: AnyObject] else { throw ResponseMapperError.invalid }
        if let item = parse(json) {
            return item
        } else {
            throw ResponseMapperError.missingAttribute
        }
    }
}

```

解析登录返回的数据

```swift
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
```

解析json数组对象：

```swift
import Foundation

final class ArrayResponseMapper<A: ParsedItem> {
    
    static func process(_ obj: AnyObject?, mapper: ((Any?) throws -> A)) throws -> [A] {
        guard let json = obj as? [[String: AnyObject]] else { throw ResponseMapperError.invalid }
        
        var items = [A]()
        for jsonNode in json {
            let item = try mapper(jsonNode)
            items.append(item)
        }
        return items
    }
}
```

要使用解析数组的，将继承的类更改，调用ArrayResponseMapper的process即可

其他的代码，就不粘上来了，源码我上传到GitHub，关于这个框架，可扩展性很强，后期可以丰富很多进去，欢迎大家给我提issue

