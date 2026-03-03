import bcrypt
import std/sysrand
import db_connector/db_sqlite
import enums

const TokenCharacters =
  "abcdefghijklmnopqrstuvwxyz" &
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ" &
  "0123456789"
const TokenLength = 64

const LegalUsernameChars =
  "abcdefghijklmnopqrstuvwxyz" &
  "0123456789" &
  "_"

proc generateToken*(): string =
  result = newString(TokenLength)
  var bytes = urandom(TokenLength)

  for i in 0..<TokenLength:
    result[i] = TokenCharacters[bytes[i] mod TokenCharacters.len]

proc digestPassword*(password: string): (string, string) =
  ## Creates a hash of the user's password using bcrypt
  let salt = genSalt(10)
  let hashed = hash(password, salt)
  return (hashed, salt)

proc checkUsername*(username: string): bool =
  ## Checks if a username is legal.
  ## Returns true if it,
  ## False if it isn't.
  for charcter in username:
    if not LegalUsernameChars.contains(charcter):
      return false
  return true

proc fetchToken*(username: string): string =
  ## Gets the token from given username.
  ## Returns empty token if user doesn't exist
  let db = open("imp.db", "", "", "")
  let rows = db.getAllRows(sql"""
    SELECT token FROM accounts WHERE username = ?;
  """, username)
  db.close()
  if len(rows) == 0:
    return ""
  
  return rows[0][0]

proc checkPassword*(username: string, password: string): bool =
  let db = open("imp.db", "", "", "")
  let rows = db.getAllRows(sql"""
    SELECT password_hash FROM accounts WHERE username = ?;
  """, username)
  db.close()

  if rows.len == 0:
    return false

  let storedHash = rows[0][0]
  if storedHash.len < 29:
    return false

  let salt = storedHash[0..28]
  let computedHash = hash(password, salt)
  return compare(storedHash, computedHash)

proc authenticateUser*(username: string, password: string): tuple[token: string, result: AuthenticationResult] =
  ## Authenticates user via password
  if username.len == 0 or password.len == 0:
    return ("", UserNotFoundError)
  if checkPassword(username, password):
    return (fetchToken(username), AuthenticationSuccess)
  else:
    return ("", IncorrectPasswordError)