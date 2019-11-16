#!/bin/sh

set -e

root_file="$1"
working_directory="$2"
compiler="$3"
args="$4"
extra_packages="$5"
extra_system_packages="$6"

if [ -n "$extra_system_packages" ]; then
  for pkg in $extra_system_packages; do
    echo "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [ -n "$extra_packages" ]; then
  echo "::warning ::Input 'extra_packages' is deprecated. We now build LaTeX document with full TeXLive installed."
fi

if [ -n "$working_directory" ]; then
  cd "$working_directory"
fi

# shellcheck disable=SC2086
"$compiler" $args "$root_file"
