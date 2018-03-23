import NIO
import NIOHTTP1

public class HTTPServer {
    
    public var delegate: Router

    public private(set) var port: Int?

    public var allowPortReuse: Bool = false

    let eventLoopGroup = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
   
    private let maxPendingConnections = 100

    public init(with router: Router) { 
        self.delegate = router
    }

    public func listen(port: Int, errorHandler: ((Swift.Error) -> Void)? = nil) { 
        self.port = port

        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 100)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: allowPortReuse ? 1 : 0)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().then {
                    channel.pipeline.add(handler: HTTPHandler(router: self.delegate))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            

        let serverChannel = try! bootstrap.bind(host: "127.0.0.1", port: port)
            .wait()
        try! serverChannel.closeFuture.wait()
    }

    public static func listen(port: Int, delegate: Router, errorHandler: ((Swift.Error) -> Void)? = nil) -> HTTPServer {
        let server = HTTPServer(with: delegate)
        server.listen(port: port, errorHandler: errorHandler)
        return server
    }

    public func stop() { 
        try! eventLoopGroup.syncShutdownGracefully()
    }
}

public class HTTPHandler: ChannelInboundHandler {
     let router: Router 
     var serverRequest: HTTPServerRequest!
     var serverResponse: HTTPServerResponse!

     public init(router: Router) {
         self.router = router
     }

     public typealias InboundIn = HTTPServerRequestPart
     public typealias OutboundOut = HTTPServerResponsePart

     public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
         let request = self.unwrapInboundIn(data)

         switch request {
         case .head(let header):
             print(header.uri)
             serverRequest = HTTPServerRequest(ctx: ctx, header: header)
         case .body(let buffer):
             serverRequest.setBuffer(buffer: buffer)           
         case .end(_):
             serverResponse = HTTPServerResponse(ctx: ctx, handler: self)
             router.handle(serverRequest, serverResponse)
         }
     }
}
