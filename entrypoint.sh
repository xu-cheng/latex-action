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
work_in_root_file_dir="${4}"
compiler="${5}"
args="${6}"
extra_packages="${7}"
extra_system_packages="${8}"
extra_fonts="${9}"
pre_compile="${10}"
post_compile="${11}"
latexmk_shell_escape="${12}"
latexmk_use_lualatex="${13}"
latexmk_use_xelatex="${14}"

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
  shopt -s extglob
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

if [[ -n "$extra_fonts" ]]; then
  readarray -t extra_fonts <<< "$extra_fonts"
  expanded_extra_fonts=()
  for pattern in "${extra_fonts[@]}"; do
    expanded="$(compgen -G "$pattern" || echo "$pattern")"
    readarray -t files <<< "$expanded"
    expanded_extra_fonts+=("${files[@]}")
  done
  extra_fonts=("${expanded_extra_fonts[@]}")

  mkdir -p "$HOME/.local/share/fonts/"

  for f in "${extra_fonts[@]}"; do
    if [[ -z "$f" ]]; then
      continue
    fi

    info "Install font $f"
    cp -r "$f" "$HOME/.local/share/fonts/"
  done

  fc-cache -fv
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

  if [[ -n "$work_in_root_file_dir" ]]; then
    pushd "$(dirname "$f")" >/dev/null
    f="$(basename "$f")"
    info "Compile $f in $PWD"
  else
    info "Compile $f"
  fi

  if [[ ! -f "$f" ]]; then
    error "File '$f' cannot be found from the directory '$PWD'."
  fi

  "$compiler" "${args[@]}" "$f"

  if [[ -n "$work_in_root_file_dir" ]]; then
    popd >/dev/null
  fi
done


if [[ -n "$post_compile" ]]; then
  info "Run post compile commands"
  eval "$post_compile"
fi
