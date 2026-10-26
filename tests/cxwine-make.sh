#!/bin/bash
export PATH="/opt/homebrew/opt/bison/bin:/opt/homebrew/opt/flex/bin:/opt/homebrew/opt/mingw-w64/bin:/opt/homebrew/bin:$PATH"
cd ~/cxwine/wine64 && make -j8
