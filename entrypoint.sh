#!/bin/sh

set -e

root_file="$1"
working_directory="$2"
compiler="$3"
args="$4"
extra_packages="$5"

if [ -n "$extra_packages" ]; then
  tlmgr update --self
  for pkg in $extra_packages; do
    echo "Install $pkg"
    tlmgr install "$pkg"
  done
fi

if [ -n "$working_directory" ]; then
  cd "$working_directory"
fi

texliveonfly -c "$compiler" -a "$args" "$root_file"
