#!/bin/zsh
set -e

# Xcode Cloud clones a fresh checkout, so Config/Secrets.xcconfig (gitignored)
# never exists there. Re-materialize it from the GEMINI_API_KEY environment
# variable configured on the Xcode Cloud workflow (App Store Connect ->
# Xcode Cloud -> workflow -> Environment -> Environment Variables, marked
# Secret). Config/Shared.xcconfig does `#include? "Secrets.xcconfig"`, so
# this file just needs to exist with the right value before the build starts.

echo "GEMINI_API_KEY = ${GEMINI_API_KEY:-}" > "$CI_PRIMARY_REPOSITORY_PATH/Config/Secrets.xcconfig"
