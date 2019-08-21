#!/bin/sh

set -e

root_file="$1"
compiler="$2"
args="$3"
extra_packages="$4"

if [ -n "$extra_packages" ]; then
  tlmgr update --self
  for pkg in $extra_packages; do
    echo "Install $pkg"
    tlmgr install "$pkg"
  done
fi

texliveonfly -c "$compiler" -a "$args" "$root_file"
