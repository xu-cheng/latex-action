#!/usr/bin/env bash

set -e

info() {
  echo -e "\033[1;34m$1\033[0m"
}

warn() {
  echo "::warning :: $1"
}

error() {
  echo "::error :: $1"
  exit 1
}

root_file="${1}"
glob_root_file="${2}"
working_directory="${3}"
compiler="${4}"
args="${5}"
extra_packages="${6}"
extra_system_packages="${7}"
pre_compile="${8}"
post_compile="${9}"
latexmk_shell_escape="${10}"
latexmk_use_lualatex="${11}"
latexmk_use_xelatex="${12}"

if [[ -z "$root_file" ]]; then
  error "Input 'root_file' is missing."
fi

readarray -t root_file <<< "$root_file"

if [[ -n "$working_directory" ]]; then
  if [[ ! -d "$working_directory" ]]; then
    mkdir -p "$working_directory"
  fi
  cd "$working_directory"
fi

if [[ -n "$glob_root_file" ]]; then
    expanded_root_file=()
    for pattern in "${root_file[@]}"; do
      expanded="$(compgen -G "$pattern" || echo "$pattern")"
      readarray -t files <<< "$expanded"
      expanded_root_file+=("${files[@]}")
    done
    root_file=("${expanded_root_file[@]}")
fi

if [[ -z "$compiler" && -z "$args" ]]; then
  warn "Input 'compiler' and 'args' are both empty. Reset them to default values."
  compiler="latexmk"
  args="-pdf -file-line-error -halt-on-error -interaction=nonstopmode"
fi

IFS=' ' read -r -a args <<< "$args"

if [[ "$compiler" = "latexmk" ]]; then
  if [[ -n "$latexmk_shell_escape" ]]; then
    args+=("-shell-escape")
  fi

  if [[ -n "$latexmk_use_lualatex" && -n "$latexmk_use_xelatex" ]]; then
    error "Input 'latexmk_use_lualatex' and 'latexmk_use_xelatex' cannot be used at the same time."
  fi

  if [[ -n "$latexmk_use_lualatex" ]]; then
    for i in "${!args[@]}"; do
      if [[ "${args[i]}" = "-pdf" ]]; then
        unset 'args[i]'
      fi
    done
    args+=("-lualatex")
    # LuaLaTeX use --flag instead of -flag for arguments.
    for VAR in -file-line-error -halt-on-error -shell-escape; do
      for i in "${!args[@]}"; do
        if [[ "${args[i]}" = "$VAR" ]]; then
          args[i]="-$VAR"
        fi
      done
    done
    args=("${args[@]/#-interaction=/--interaction=}")
  fi

  if [[ -n "$latexmk_use_xelatex" ]]; then
    for i in "${!args[@]}"; do
      if [[ "${args[i]}" = "-pdf" ]]; then
        unset 'args[i]'
      fi
    done
    args+=("-xelatex")
  fi
else
  for VAR in "${!latexmk_@}"; do
    if [[ -n "${!VAR}" ]]; then
      error "Input '${VAR}' is only valid if input 'compiler' is set to 'latexmk'."
    fi
  done
fi

if [[ -n "$extra_system_packages" ]]; then
  for pkg in $extra_system_packages; do
    info "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [[ -n "$extra_packages" ]]; then
  warn "Input 'extra_packages' is deprecated. We now build LaTeX document with full TeXLive installed."
fi

if [[ -n "$pre_compile" ]]; then
  info "Run pre compile commands"
  eval "$pre_compile"
fi

for f in "${root_file[@]}"; do
  if [[ -z "$f" ]]; then
    continue
  fi

  info "Compile $f"

  if [[ ! -f "$f" ]]; then
    error "File '$f' cannot be found from the directory '$PWD'."
  fi

  "$compiler" "${args[@]}" "$f"
done

if [[ -n "$post_compile" ]]; then
  info "Run post compile commands"
  eval "$post_compile"
fi
