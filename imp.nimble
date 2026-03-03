# Package

version       = "0.1.0"
author        = "Stormy"
description   = "Internet Messaging Project"
license       = "MIT"
srcDir        = "src"
bin           = @["imp"]


# Dependencies

requires "nim >= 2.2.8"
requires "bcrypt >= 0.2.1"
requires "db_connector >= 0.1.0"
requires "mummy >= 0.4.7"