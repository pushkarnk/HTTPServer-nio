import NIO
import NIOHTTP1
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
    private let ctx: HTTPHandler 
    private let request: HTTPRequestHead
    private let handler: ChannelInboundHandler

    public init(ctx: ChannelHandlerContext, request: HTTPRequestHead, handler: HTTPHandler) {
        self.ctx = ctx
        self.request = request
        self.handler = handler
    }
    
    public var headers = HTTPHeaders()
  
    private var status = HTTPResponseStatus.ok.rawValue()

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
        try write(from: string.data(using: .utf8)!)
    }

    public func write(from data: Data) throws {
        var buffer = ctx.channel.allocator.buffer(capacity: 100)
        buffer.write(string: String(data: data, encoding: .utf8)!)
        let response = HTTPResponseHead(version: request.version, status: .ok, headers: headers)
        ctx.write(handler.wrapOutboundOut(.head(response)), promise: nil)
        ctx.write(handler.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        ctx.writeAndFlush(handler.wrapOutboundOut(.end(nil)))
    }

    public func end(text: String) throws {
        try write(from: text)
        try end()
    }

    public func end() throws {
        ctx.flush()
        ctx.close()
    }

    public func reset() { }
} 
