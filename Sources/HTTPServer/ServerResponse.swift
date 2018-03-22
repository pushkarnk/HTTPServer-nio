import Foundation

public protocol ServerResponse: class {
    
    var statusCode: HTTPResponseStatus? { get set }
    
    var headers : HTTPHeaders { get }
    
    func write(from string: String) throws
    
    func write(from data: Data) throws
    
    func end(text: String) throws
    
    func end() throws
    
    func reset()
}

public class HTTPServerResponse {
    private let ctx: ChannelContextHandler

    public init(ctx: ChannelContextHandler) {
        self.ctx = ctx
    }
    
    public var headers = HTTPHeaders()
  
    private var status = HTTPResponseStatus.ok.rawValue

    public var statusCode: HTTPResponseStatus {
        get {
            return HTTPResponseStatus(rawValue: status)
        }
        set(newValue) {
            if let newValue = newValue {
                status = newValue.rawValue
            }
        }
    }

    public func write(from string: String) throws {
        write(from: string.data(using: .utf8))
    }

    public func write(from data: Data) throws {
    }

    pubic func end(text: String) throws {
    }

    public func end() throws {
    }

    public func reset() { }
    
