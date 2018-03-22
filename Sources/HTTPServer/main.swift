import NIO
import NIOHTTP1

public class HTTPServer {
    
    public var delegate: Router

    public private(set) var port: Int?

    //public private(set) var state: ServerState = .unknown

    public var allowPortReuse: Bool = false

    //public var keepAliveState: KeepAliveState = .unlimited

    let eventLoopGroup = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
   
    private let maxPendingConnections = 100

    public init(with router: Router) { 
        self.delegate = router
    }

    public func listen(port: Int, errorHandler: ((Swift.Error) -> Void)? = nil) { 
        self.port = port

        //bootstrap server
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 100)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: allowPortReuse ? 1 : 0)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().then {
                    channel.pipeline.add(handler: HTTPHandler(router: self.delegate))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            

        //bind and wait
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

class HTTPHandler: ChannelInboundHandler {
     let router: Router 

     public init(router: Router) {
         self.router = router
     }

     typealias InboundIn = HTTPServerRequestPart

     func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
         let request = self.unwrapInboundIn(data)

         switch request {
         case .head(let header):
             print("header = \(header)")
             switch header.method.hasRequestBody {
             case .no, .unlikely: router.handle() 
             case .yes: break
             }
         case .body(let buffer):
             print("buffer = \(buffer)")
             router.handle()
         case .end(let end0):
             print("end = \(end0)")
         }
     }
}


public class Router {
    public func handle() {
        print("Called Router.handle")
    }
}

_ = HTTPServer.listen(port: 35191, delegate: Router())

