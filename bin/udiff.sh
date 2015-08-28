#!/bin/bash

# usage
if [[ $# -lt 1 ]];
then
  echo -e "Show USE difference from binary & source package\n"
  echo "Usage: $0 category/pkg"
  exit 1
fi

# check deps
if [[ ! -x /usr/bin/equery ]];
then
  echo "Please install app-portage/gentoolkit. Required to work"
  exit 1
fi

# load Packages data
[ -z $TMPDIR ] && TMPDIR=/tmp
if [[ ! -s $TMPDIR/Packages ]];
then
    echo "Query portage binary host"
    eval $(emerge --info | grep PORTAGE_BINHOST)
    for url in $PORTAGE_BINHOST;
    do
      echo "Downloading ${url}/Packages"
      wget -q $url/Packages -O $TMPDIR/Packages 2>/dev/null
      [ -s $TMPDIR/Packages ] && break
    done
    if [[ ! -f $TMPDIR/Packages ]];
    then
      echo -e 'Error: Can not load packages file from binary host'
      exit 1
    fi
fi

# escape '/' character in pkg name for sed
QUERY=$(echo $1 | sed 's@/@\\/@')
# extract block of lines between CTV: ${PKG} and USE, then save last line
BINUSE=$(sed -n "/^CPV: ${QUERY}[0-9._pre-]\+$/,/^USE:.*/p" $TMPDIR/Packages | sed -n '$p') 
if [[ -z $BINUSE ]];
then
  echo "Error: Can not find $1 in $TMPDIR/Packages"
  echo "Please remember to specify full package name. E.g. 'media-gfx/gimp'"
  exit 1
fi
# cut "USE: " from start and split to lines for diff, then save to file
echo ${BINUSE:5} | sed 's/\s/\n/g' | sort > $TMPDIR/binuse.tmp
# query source USE flags, prepare for diff and save to file
equery -q u ${1} | sed '/^-/d' | sed 's/^.//' | sort > $TMPDIR/srcuse.tmp
# summary output
echo "Binary package '${1}' different by these USE flags:"
diff -u0 $TMPDIR/srcuse.tmp $TMPDIR/binuse.tmp | sed -n '/^[+-]\w/p'

# clean
rm -f $TMPDIR/{srcuse,binuse}.tmp
