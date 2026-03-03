import db_connector/db_sqlite
import auth, enums

proc tryCreateDatabase*() =
  ## Creates the database if it doesn't exist.
  let db = open("imp.db", "", "", "")
  db.exec(sql"""
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      token TEXT UNIQUE,
      token_expires_at DATETIME DEFAULT (DATETIME('now', '+6 months')),
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  """)
  db.close()

proc createAccount*(username: string, password: string): AccountCreateResult =
  ## Creates a user account with a username and password.
  ## Usernames must fit in the legal charcters (see auth.nim LegalUsernameChars)
  ## and passwords must be under 32 characters.
  
  # Checks if username is valid
  if checkUsername(username) == false:
    return IllegalUsernameError

  # Checks if password is too long
  if len(password) > 32:
    return PasswordTooBigError

  tryCreateDatabase()

  let db = open("imp.db", "", "", "")

  let rows = db.getAllRows(sql"""
    SELECT id FROM accounts WHERE username = ?;
  """, username)

  if len(rows) > 0:
    db.close()
    return AccountExistsError

  db.exec(sql"""
    INSERT INTO accounts (username, password_hash, token)
    VALUES (?, ?, ?);
  """, username, auth.digestPassword(password)[0], auth.generateToken())
  db.close()

  return CreationSuccess