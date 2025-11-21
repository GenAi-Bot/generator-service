# Package

version       = "0.1.8"
author        = "bit0r1n"
description   = "Generator service for GenAi Discord bot"
license       = "GPL-3.0"
srcDir        = "src"
binDir        = "bin"
bin           = @["genai_generator"]


# Dependencies

requires "nim >= 1.6.10"
requires "redis, jsony"
