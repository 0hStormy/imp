import mummy, mummy/routers
import json
import strutils
import os
import mimetypes
import db, enums, auth

proc serveStatic(request: Request) =
  var path = request.path

  # Default file
  if path == "/":
    path = "/index.html"

  # Prevent directory traversal
  if path.contains(".."):
    var headers: HttpHeaders
    request.respond(403, headers, "Forbidden")
    return

  let cleanPath = if path.startsWith("/"): path[1..^1] else: path
  let filePath = "static" / cleanPath

  if fileExists(filePath):
    var headers: HttpHeaders
    let ext = splitFile(filePath).ext
    headers["Content-Type"] = getMimetype(newMimeTypes(), ext)
    request.respond(200, headers, readFile(filePath))
  else:
    # 404 Fallback
    if fileExists("static/404.html"):
      var headers: HttpHeaders
      headers["Content-Type"] = "text/html"
      request.respond(200, headers, readFile("static/404.html"))
    else:
      var headers: HttpHeaders
      request.respond(404, headers, "Not Found")

proc respondJson(req: Request, code: int, node: JsonNode) =
  ## Sends response to client with specified JSON data
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  req.respond(code, headers, $node)

proc checkForJson(req: Request): bool =
  ## Checks if the request has JSON data in the body
  let contentType = req.headers["Content-Type"]
  return contentType.toLowerAscii().startsWith("application/json")

proc apiCreateAccount(request: Request) =
  ## Handles HTTP request for creating account
  if not checkForJson(request):
    respondJson(request, 415, %*{
      "error": "Please provide JSON in your request"
    })
    return

  try:
    let body = parseJson(request.body)

    # Make sure JSON body is a proper object
    if body.kind != JObject:
      respondJson(request, 400, %*{
        "error": "JSON body must be an object"
      })
      return

    # Make sure request has a username a password field
    if not body.hasKey("username") or not body.hasKey("password"):
      respondJson(request, 400, %*{
        "error": "Missing username or password"
      })
      return

    # Converts username and password objects to usable strings
    let username = body["username"].getStr()
    let password = body["password"].getStr()

    let status = createAccount(username, password)

    if status == CreationSuccess:
      respondJson(request, 200, %*{
        "status": $status
      })
    else:
      respondJson(request, 400, %*{
        "error": $status
      })

  # Checks for invalid or malformed JSON
  except JsonParsingError:
    respondJson(request, 400, %*{
      "error": "Malformed JSON data"
    })

proc apiLogin(request: Request) =
  ## Handles HTTP request for getting a user's token
  if not checkForJson(request):
    respondJson(request, 415, %*{
      "error": "Please provide JSON in your request"
    })
    return
  try:
    let body = parseJson(request.body)
    if body.kind != JObject:
      respondJson(request, 400, %*{
        "error": "JSON body must be an object"
      })
      return
    if not body.hasKey("username") or not body.hasKey("password"):
      respondJson(request, 400, %*{
        "error": "Missing username or password"
      })
      return
    
    let username = body["username"].getStr()
    let password = body["password"].getStr()
    let authResult = authenticateUser(username, password)
    if authResult.result == AuthenticationSuccess:
      respondJson(request, 200, %*{
        "token": authResult.token
      })
    else:
      respondJson(request, 401, %*{
        "error": "Invalid username or password"
      })
  except JsonParsingError:
    respondJson(request, 400, %*{
      "error": "Malformed JSON data"
    })


# Initialize database
tryCreateDatabase()

# Initialize HTTP router/server
var router: Router

# API endpoints
router.post("/api/createAccount", apiCreateAccount)
router.post("/api/login", apiLogin)
router.get("/*", serveStatic)

let server = newServer(router)
echo "Serving on http://localhost:8810"
server.serve(Port(8810))