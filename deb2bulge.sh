#!/usr/bin/env bash

SHEATH=$(which sheath)
if [ -z "$SHEATH" ]; then
  echo "sheath not found in your path! please add sheath to your path (:"
  exit 1
fi

function usage() {
  echo "usage: deb2bulge.sh <current url>"
  exit 1
}

function err_no_file() {
  echo "file not found: $1"
  exit 1
}

# returns the likely name of the file that the url will download to
# removes the https://<domain>/ from the url and just returns the <name>.deb
# TODO! this is very much a hack, and we should see if we can instead get it from curl
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

URL=$1
DEBNAME=$(url_likely_download_name "$URL")

if [ -z "$URL" ]; then
  usage
fi

mkdir -p work
cd work || err_no_file "work"
mkdir -p tmp

cd tmp || err_no_file "tmp"

echo "deb2bulge.sh: converting $NAME $VERSION from $URL"
echo "deb2bulge.sh: downloading $URL to get sha512sum"
curl --output "$DEBNAME" "$URL" -L
echo "deb2bulge.sh: calculating sha512sum"
SHA=$(sha512sum "$DEBNAME" | awk '{print $1}')

echo "deb2bulge.sh: extracting control file from $DEBNAME"
ar x "$DEBNAME" control.tar.xz
echo "deb2bulge.sh: extracting control file from control.tar.xz"
tar -xf control.tar.xz

echo "deb2bulge.sh: parsing control file"
NAME=$(grep -i "Package:" control | awk '{print $2}')
VERSION=$(grep -i "Version:" control | awk '{print $2}')
DESC=$(grep -i "Description:" control | sed -e 's/Description: //')
HOMEPAGE=$(grep -i "Homepage:" control | awk '{print $2}')

URLFINAL=$(replace_version_in_url "$VERSION" "$URL")

cd ..

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
DESC="$DESC"
GRPS=()
URL="$HOMEPAGE"
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