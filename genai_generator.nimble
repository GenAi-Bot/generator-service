# Package

version       = "0.1.4"
author        = "bit0r1n"
description   = "Generator service for GenAi Discord bot"
license       = "Proprietary"
srcDir        = "src"
binDir        = "bin"
bin           = @["genai_generator"]


# Dependencies

requires "nim >= 1.6.10"
requires "redis"
