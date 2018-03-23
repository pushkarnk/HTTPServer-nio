public class Router {
    typealias Handler = (HTTPServerRequest, HTTPServerResponse)->Void

    var handlers: [String: Handler] = [:]

    public func handle(_ serverRequest: HTTPServerRequest, _ serverResponse: HTTPServerResponse) {
        let handler = handlers[serverRequest.method+String(data: serverRequest.url, encoding: .utf8)!]!
        handler(serverRequest, serverResponse) 
    }

    public func get(_ path: String, handler: @escaping (HTTPServerRequest, HTTPServerResponse)->Void) {
        handlers["GET"+path] = handler
    }

}
