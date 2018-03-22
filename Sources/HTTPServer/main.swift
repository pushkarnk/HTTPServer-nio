let router = Router()
router.get("/api") { request, response in
    try! response.end(text: "Hello, World!")
}

router.get("/") { request, response in 
    try! response.end(text: "Hello, Runtimes!\n")
}

_ = HTTPServer.listen(port: 35191, delegate: router)

