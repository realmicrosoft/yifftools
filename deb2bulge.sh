#!/usr/bin/env bash

SHEATH=$(which sheath)
if [ -z "$SHEATH" ]; then
  echo "sheath not found in your path! please add sheath to your path (:"
  exit 1
fi

function usage() {
  echo "usage: deb2bulge.sh <package name> <version> <current url>"
  exit 1
}

function err_no_file() {
  echo "file not found: $1"
  exit 1
}

# returns the likely name of the file that the url will download to
# removes the https://<domain>/ from the url and just returns the <name>.deb
function url_likely_download_name() {
  echo "$1" | sed -e 's/https:\/\/.*\///'
}

# takes in a version string and a url, and replaces all occurrences of the version string in the url with ${VERSION}
function replace_version_in_url() {
  echo "$2" | sed -e "s/$1/\${VERSION}/"
}

if [ -z "$1" ]; then
  usage
fi

NAME=$1
VERSION=$2
URL=$3
DEBNAME=$(url_likely_download_name "$URL")
URLFINAL=$(replace_version_in_url "$VERSION" "$URL")

if [ -z "$NAME" ]; then
  usage
fi
if [ -z "$VERSION" ]; then
  usage
fi
if [ -z "$URL" ]; then
  usage
fi

mkdir -p work
cd work || err_no_file "work"

echo "deb2bulge.sh: converting $NAME $VERSION from $URL"
echo "deb2bulge.sh: downloading $URL to get sha512sum"
curl --output "$NAME.deb" "$URL"
echo "deb2bulge.sh: calculating sha512sum"
SHA=$(sha512sum "$NAME.deb" | awk '{print $1}')


mkdir -p "$NAME"
OUTFOLDER="$(pwd)/$NAME"
cd "$NAME" || err_no_file "$NAME"
cat > PKGSCRIPT << EOF
# Package Maintainers
MAINTAINERS=("Name <email@mail.com>")

# Package information
NAME="$NAME"
VERSION="$VERSION"
EPOCH=0
DESC="FILLME"
GRPS=()
URL="FILLME"
LICENSES=("FILLME")
DEPENDS=("FILLME")
OPT_DEPENDS=()
MK_DEPENDS=("ar" "tar" "gzip" "bzip2" "xz")
PROVIDES=("$NAME")
CONFLICTS=()
REPLACES=()

# Source information
SRC=("$URLFINAL")

SUM_TYPE="sha512"
SUM=("$SHA")

# Prepare script
function prepare() {
    cd "\${WORKDIR}"

    mkdir \${NAME}-\${VERSION}
    cd    \${NAME}-\${VERSION}

    ar x \${WORKDIR}/$DEBNAME

    mkdir out
    cd    out

    tar xvf ../data.tar.xz

    return 0
}

# Build script
function build() {
    return 0
}

# Post build script
function postbuild() {
    cd "\${WORKDIR}/\${NAME}-\${VERSION}/out"

    cp -r ./ \${BUILD_DATA_ROOT}/

    return 0
}
EOF

echo "deb2bulge.sh: running sheath"
echo "deb2bulge.sh: done! you can find the (uncompiled) bulge package in $OUTFOLDER"