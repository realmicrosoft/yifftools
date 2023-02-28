#!/usr/bin/env bash

if [ -z "$PACKAGES_DIR" ]; then
  PACKAGES_DIR=$(pwd)
  echo "PACKAGES_DIR not set, defaulting to $PACKAGES_DIR (working directory)"
fi

FAILED=0

# check that the directory contains a PKGSCRIPT
function check_pkgscript() {
  PKGSCRIPT="$PACKAGES_DIR/$1/PKGSCRIPT"
  if [ ! -f "$PKGSCRIPT" ]; then
    echo "$1: PKGSCRIPT not found!"
    FAILED=1
  fi
}

# check that the directory name, and the name provided by the PKGSCRIPT match
function check_package_name() {
  DIRECTORY="$1"
  PKGSCRIPT="$PACKAGES_DIR/$DIRECTORY/PKGSCRIPT"
  eval "$(. "$PKGSCRIPT"; echo "NAME=$NAME")"
  if [ "$DIRECTORY" != "$NAME" ]; then
    echo "$1: directory name and package name (PKGSCRIPT) do not match: $DIRECTORY != $NAME"
    FAILED=1
  fi
}

# check that the directory contains a PKGINFO
function check_pkginfo() {
  PKGINFO="$PACKAGES_DIR/$1/PKGINFO"
  if [ ! -f "$PKGINFO" ]; then
    echo "$1: PKGINFO not found!"
    FAILED=1
  fi
}

# check that PKGINFO has the same name as the directory
function check_pkginfo_name() {
  DIRECTORY="$1"
  PKGINFO="$PACKAGES_DIR/$DIRECTORY/PKGINFO"
  GIVEN_NAME=$(cat "$PKGINFO" | grep name | awk '{print $2}' | grep -Po '[^\",]+' | head -n 1)
  if [ "$DIRECTORY" != "$GIVEN_NAME" ]; then
    echo "$1: directory name and package name (PKGINFO) do not match: $DIRECTORY != $GIVEN_NAME"
    FAILED=1
  fi
}

# check that the PKGSCRIPT's description isn't the iw description
# (nl80211 based CLI configuration utility for wireless devices.)
function check_iw_description() {
  PKGSCRIPT="$PACKAGES_DIR/$1/PKGSCRIPT"
  eval "$(. "$PKGSCRIPT"; echo "DESC=\"$DESC\"")"
  if [ "$DESC" = "nl80211 based CLI configuration utility for wireless devices." ]; then
    echo "$1: description is the iw description, please change it"
    FAILED=1
  fi
}

# for each directory in the packages directory, run above checks
echo "checking packages directory for sanity"
for DIRECTORY in "$PACKAGES_DIR"/*; do
  if [ ! -d "$DIRECTORY" ]; then
    continue
  fi
  DIRECTORY=$(basename "$DIRECTORY")
  check_pkgscript "$DIRECTORY"
  # make sure there's a PKGSCRIPT before running following checks
  if [ -f "$PACKAGES_DIR/$DIRECTORY/PKGSCRIPT" ]; then
    check_package_name "$DIRECTORY"
    # don't run the iw description check on the iw package
    if [ "$DIRECTORY" != "iw" ]; then
      check_iw_description "$DIRECTORY"
    fi
  fi
  check_pkginfo "$DIRECTORY"
  # make sure there's a PKGINFO before running following checks
  if [ -f "$PACKAGES_DIR/$DIRECTORY/PKGINFO" ]; then
    check_pkginfo_name "$DIRECTORY"
  fi
done

if [ "$FAILED" = "1" ]; then
  echo "sanity check failed, please fix the above errors"
  exit 1
fi