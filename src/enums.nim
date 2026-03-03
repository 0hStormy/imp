type
  AccountCreateResult* = enum
    CreationSuccess
    AccountExistsError
    IllegalUsernameError
    PasswordTooBigError

type
  AuthenticationResult* = enum
    AuthenticationSuccess
    UserNotFoundError
    IncorrectPasswordError