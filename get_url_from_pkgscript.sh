#!/usr/bin/env bash
# gets the SRC url from a PKGSCRIPT, intended for use in recursive_update.sh
# WARNING: THIS SCRIPT ASSUMES THAT THE REQUIRED URL IS THE FIRST ENTRY IN THE SRC ARRAY

PKGSCRIPT="$1"
if [ -z "$PKGSCRIPT" ]; then
  echo "usage: get_url_from_pkgscript.sh <PKGSCRIPT>"
  exit 1
fi

if [ ! -f "$PKGSCRIPT" ]; then
  echo "file not found: $PKGSCRIPT"
  exit 1
fi

. "$PKGSCRIPT"

echo "${SRC[0]}"