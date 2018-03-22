import NIO
import NIOHTTP1 
import Foundation

public protocol ServerRequest: class {
    
    var headers : HTTPHeaders { get }

    var url : Data { get }

    var urlURL : URL { get }

    var remoteAddress: String { get }
    
    var httpVersionMajor: UInt16? { get }

    var httpVersionMinor: UInt16? { get }
    
    var method: String { get }
    
    func read(into data: inout Data) throws -> Int
    
    func readString() throws -> String?

    func readAllData(into data: inout Data) throws -> Int
}

public class HTTPServerRequest: ServerRequest {
    public var headers : HTTPHeaders

    public var url : Data

    public var urlURL: URL

    public var remoteAddress: String

    public var httpVersionMajor: UInt16? 

    public var httpVersionMinor: UInt16?

    public var method: String

    private var buffer: ByteBuffer!

    public init(ctx: ChannelHandlerContext, header: HTTPRequestHead) {
        self.headers = header.headers
        self.method = String(describing: header.method)
        self.httpVersionMajor = header.version.major
        self.httpVersionMinor = header.version.minor
        self.url = header.uri.data(using: .utf8) ?? Data()
        self.urlURL = URL(string: header.uri)!
        self.remoteAddress = ctx.remoteAddress?.description ?? ""
    }

    public func setBuffer(buffer: ByteBuffer) {
        self.buffer = buffer
    }

    public func read(into data: inout Data) throws -> Int {
        let count = buffer.readableBytes
        let bytes = buffer.readBytes(length: count)!
        data.append(contentsOf: bytes) 
        buffer.moveReaderIndex(to: 0)
        return count
    }

    public func readString() throws -> String? {
        var data = Data()
        _ = try! read(into: &data)
        return String(data: data, encoding: .utf8)
    }

    public func readAllData(into data: inout Data) throws -> Int {
        return try! read(into: &data)
    }
}
