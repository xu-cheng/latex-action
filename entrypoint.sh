#!/bin/sh

set -e

warn() {
  echo "::warning :: $1"
}

error() {
  echo "::error :: $1"
  exit 1
}

root_file="$1"
working_directory="$2"
compiler="$3"
args="$4"
extra_packages="$5"
extra_system_packages="$6"

if [ -z "$root_file" ]; then
  error "Input 'root_file' is missing."
fi

if [ -z "$compiler" ] && [ -z "$args" ]; then
  warn "Input 'compiler' and 'args' are both empty. Reset them to default values."
  compiler="latexmk"
  args="-pdf -file-line-error -interaction=nonstopmode"
fi

if [ -n "$extra_system_packages" ]; then
  for pkg in $extra_system_packages; do
    echo "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [ -n "$extra_packages" ]; then
  warn "Input 'extra_packages' is deprecated. We now build LaTeX document with full TeXLive installed."
fi

if [ -n "$working_directory" ]; then
  cd "$working_directory"
fi

if [ ! -f "$root_file" ]; then
  error "File '$root_file' cannot be found from the directory '$PWD'."
fi

# shellcheck disable=SC2086
"$compiler" $args "$root_file"
