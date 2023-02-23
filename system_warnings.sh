#!/usr/bin/env bash
### this script checks your yiffOS system for common issues related to packaging mistakes
### it is intended to be run by the yiffOS team to check for common mistakes in the yiffOS repository,
### but it can also be run by users to check their own system for errors
### note that warnings do not necessarily mean that something is wrong; they are just to inform you of common mistakes

BULGETOOL=$(which bulgetool)

if [ -z "$BULGETOOL" ]; then
  echo "bulgetool not found in your path! please add bulgetool to your path (:"
  exit 1
fi


### LIB64 WARNING: this warning is to inform you that you have a package that installs to /usr/lib64
### this isn't necessarily bad on it's own, but it can be an issue if a package is installed only to /usr/lib64
### and not to /usr/lib; this can cause issues with other packages that expect to find libraries in /usr/lib
### note: this doesn't count symlinks as installed to /usr/lib64 if they link to /usr/lib
function warn_lib64() {
  find /usr/lib64 -depth -exec "$BULGETOOL" blame {} \;
}

### LONG BUILD COMMAND WARNING: this warning is to inform you that you have a package that has a build command that
### is over 80 characters long. this is more of a style issue than anything else, but it's nice to keep things
### consistent! (:
function warn_long_build_command() {
  PACKAGE_DIR="$1"
  BUILD_COMMANDS="make ./configure meson ninja cmake cargo go"
  for BUILD_COMMAND in $BUILD_COMMANDS; do
    grep "\b$BUILD_COMMAND\b" "$PACKAGE_DIR/PKGSCRIPT" | while read -r LINE; do
      if [ "${#LINE}" -gt 80 ]; then
        echo "$LINE"
      fi
    done
  done
}


### MAIN WARNING CHECKER: runs each warning function and prints the results
function main() {
  PACKAGE="$1"
  PACKAGE_DIR="$(realpath "$2")"
  LIB64_WARNS=$(warn_lib64)
  LONG_BUILD_COMMAND_WARNS=$(warn_long_build_command "$PACKAGE_DIR")
  if [ -n "$LIB64_WARNS" ]; then
    echo "LIB64 WARNING: packages are installing to /usr/lib64!"
    echo "this can cause issues with other packages that expect to find libraries in /usr/lib"
    echo "$LIB64_WARNS" | sed 's/^/\t/'
  fi
  if [ -n "$LONG_BUILD_COMMAND_WARNS" ]; then
    echo "LONG BUILD COMMAND WARNING: build commands are over 80 characters long!"
    echo "this is more of a style issue than anything else, but it's nice to keep things consistent! (:"
    echo "$LONG_BUILD_COMMAND_WARNS" | sed 's/^/\t/'
  fi
}

main "$@"