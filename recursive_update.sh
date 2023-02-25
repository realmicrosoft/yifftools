#!/usr/bin/env bash

HOLE=$(which hole)
BULGETOOL=$(which bulgetool)
WORKING_DIR=$(realpath "$(dirname "$0")")
if [ -z "$HOLE" ]; then
  echo "hole not found in your path! please add hole to your path (:"
  exit 1
fi
if [ -z "$BULGETOOL" ]; then
  echo "bulgetool not found in your path! please add bulgetool to your path (:"
  exit 1
fi

if [ -z "$PACKAGES_DIR" ]; then
  PACKAGES_DIR=$(realpath "$(dirname "$0")/packages")
fi

function usage() {
  echo "usage: recursive_update.sh <package name>"
  exit 1
}

function err_no_file() {
  echo "file not found: $1"
  exit 1
}

function check_pkgscript() {
  PKGSCRIPT="$PACKAGES_DIR/$1/PKGSCRIPT"
  if [ ! -f "$PKGSCRIPT" ]; then
    echo "PKGSCRIPT not found for $1"
    exit 1
  fi
}

function check_for_warnings() {
  PACKAGE="$1"
  PACKAGE_DIR="$2"
  "$WORKING_DIR/system_warnings.sh" "$PACKAGE" "$PACKAGE_DIR"
}

function update() {
  PKGNAME="$1"
  EDIT_PKGSCRIPT="$2"
  check_pkgscript "$PKGNAME"

  if [ "$EDIT_PKGSCRIPT" = "edit" ]; then
    echo "$PKGNAME: you will be sent to vim, please edit the PKGSCRIPT to update the version and hash (and url if necessary)"
    echo "$PKGNAME: press enter to continue"
    read -r

    vim "$PACKAGES_DIR/$PKGNAME/PKGSCRIPT"
  fi

  echo "$PKGNAME: running sheath to rebuild and install the package"
  echo "$PKGNAME: press enter to continue, or s to skip"
  read -r -n 1 -p "s/enter: " REPLY
  if [ "$REPLY" = "s" ]; then
    echo "$PKGNAME: skipping"
  else
    cd "$PACKAGES_DIR/$PKGNAME" || err_no_file "$PACKAGES_DIR/$PKGNAME"
    env PKG_CACHE="$PACKAGES_DIR" "$HOLE" -cb -e MAKEFLAGS="-j$(nproc)"
    echo "$PKGNAME: package should be built, if build failed please press 'n'; otherwise press 'y'"
    REPLY=""
    read -r -n 1 -p "y/n: " REPLY
    if [ "$REPLY" = "n" ]; then
      echo "$PKGNAME: restarting update process"
      update "$PKGNAME" "edit"
      return
    fi
    echo "$PKGNAME: installing package"
    "$HOLE" -i
    echo "$PKGNAME: package should be installed!"
    echo "$PKGNAME: checking for warnings"
    check_for_warnings "$PKGNAME" "$PACKAGES_DIR/$PKGNAME"
    echo "$PKGNAME: done"
    echo "$PKGNAME: press y or enter to continue, or n to treat as failed build"
    REPLY=""
    read -r -n 1 -p "y/n: " REPLY
    if [ "$REPLY" = "n" ]; then
      echo "$PKGNAME: restarting update process"
      update "$PKGNAME" "edit"
      return
    fi
  fi
  echo "$PKGNAME: checking for dependencies"
  DEPS=$("$BULGETOOL" deplist "$PKGNAME")
  if [ -z "$DEPS" ]; then
    echo "$PKGNAME: no dependencies found"
    return
  fi
  # remove first line, which is the package name
  DEPS=$(echo "$DEPS" | sed -e '1d')
  DEPS_COUNT=$(echo "$DEPS" | wc -l)
  echo "$PKGNAME: found $DEPS_COUNT dependencies"
  for DEP in $DEPS; do
    echo "$PKGNAME: rebuilding $DEP"
    echo "$PKGNAME: press y to edit PKGSCRIPT, or n / enter to just rebuild; optionally, press s to skip this package or b to return from this loop"
    REPLY=""
    read -r -n 1 -p "y/n: " REPLY
    if [ "$REPLY" = "y" ]; then
      update "$DEP" "edit"
      PKGNAME="$1"
      EDIT_PKGSCRIPT="$2"
    elif [ "$REPLY" = "s" ]; then
      echo "$PKGNAME: skipping $DEP"
    elif [ "$REPLY" = "b" ]; then
      echo "$PKGNAME: breaking from loop"
      break
    else
      update "$DEP" ""
    fi
  done
  echo "$PKGNAME: done!"
  return
}

if [ -z "$1" ]; then
  usage
fi

PKGNAME="$1"
update "$PKGNAME" "edit"