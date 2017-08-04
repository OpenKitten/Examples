import Leopard

// Create an HTTP server at port `80`
let server = try WebServer()

// TODO: Set up routes
server.get { _ in
  return Future { "Hello world" }
}

// start the server
try server.start()

