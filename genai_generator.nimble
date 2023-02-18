# Package

version       = "0.1.0"
author        = "bit0r1n"
description   = "A new awesome nimble package"
license       = "Proprietary"
srcDir        = "src"
binDir        = "bin"
bin           = @["genai_generator"]


# Dependencies

requires "nim >= 1.6.10"
requires "redis"
