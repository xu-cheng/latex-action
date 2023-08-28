#!/usr/bin/env bash

set -eo pipefail
shopt -s extglob globstar nullglob

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
working_directory="${2}"
work_in_root_file_dir="${3}"
continue_on_error="${4}"
compiler="${5}"
args="${6}"
extra_system_packages="${7}"
extra_fonts="${8}"
pre_compile="${9}"
post_compile="${10}"
latexmk_shell_escape="${11}"
latexmk_use_lualatex="${12}"
latexmk_use_xelatex="${13}"

# install git on old images
if ! command -v git &>/dev/null; then
  apk --no-cache add git
fi
git config --system --add safe.directory "$GITHUB_WORKSPACE"

if [[ -z "$root_file" ]]; then
  error "Input 'root_file' is missing."
fi

readarray -t root_file <<<"$root_file"

if [[ -n "$working_directory" ]]; then
  if [[ ! -d "$working_directory" ]]; then
    mkdir -p "$working_directory"
  fi
  cd "$working_directory"
fi

expanded_root_file=()
for pattern in "${root_file[@]}"; do
  # shellcheck disable=SC2206
  expanded=($pattern)
  expanded_root_file+=("${expanded[@]}")
done
root_file=("${expanded_root_file[@]}")

if [[ -z "$compiler" && -z "$args" ]]; then
  warn "Input 'compiler' and 'args' are both empty. Reset them to default values."
  compiler="latexmk"
  args="-pdf -file-line-error -halt-on-error -interaction=nonstopmode"
fi

IFS=' ' read -r -a args <<<"$args"

if [[ "$compiler" = "latexmk" ]]; then
  if [[ "$latexmk_shell_escape" = "true" ]]; then
    args+=("-shell-escape")
  fi

  if [[ "$latexmk_use_lualatex" = "true" && "$latexmk_use_xelatex" = "true" ]]; then
    error "Input 'latexmk_use_lualatex' and 'latexmk_use_xelatex' cannot be used at the same time."
  fi

  if [[ "$latexmk_use_lualatex" = "true" ]]; then
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

  if [[ "$latexmk_use_xelatex" = "true" ]]; then
    for i in "${!args[@]}"; do
      if [[ "${args[i]}" = "-pdf" ]]; then
        unset 'args[i]'
      fi
    done
    args+=("-xelatex")
  fi
else
  for VAR in "${!latexmk_@}"; do
    if [[ "${!VAR}" = "true" ]]; then
      error "Input '${VAR}' is only valid if input 'compiler' is set to 'latexmk'."
    fi
  done
fi

if [[ -n "$extra_system_packages" ]]; then
  IFS=$' \t\n'
  for pkg in $extra_system_packages; do
    info "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [[ -n "$extra_fonts" ]]; then
  readarray -t extra_fonts <<<"$extra_fonts"
  expanded_extra_fonts=()
  for pattern in "${extra_fonts[@]}"; do
    # shellcheck disable=SC2206
    expanded=($pattern)
    expanded_extra_fonts+=("${expanded[@]}")
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

if [[ -n "$pre_compile" ]]; then
  info "Run pre compile commands"
  eval "$pre_compile"
fi

exit_code=0

for f in "${root_file[@]}"; do
  if [[ -z "$f" ]]; then
    continue
  fi

  if [[ "$work_in_root_file_dir" = "true" ]]; then
    pushd "$(dirname "$f")" >/dev/null
    f="$(basename "$f")"
    info "Compile $f in $PWD"
  else
    info "Compile $f"
  fi

  if [[ ! -f "$f" ]]; then
    error "File '$f' cannot be found from the directory '$PWD'."
  fi

  "$compiler" "${args[@]}" "$f" || ret="$?"
  if [[ "$ret" -ne 0 ]]; then
    if [[ "$continue_on_error" = "true" ]]; then
      exit_code="$ret"
    else
      exit "$ret"
    fi
  fi

  if [[ "$work_in_root_file_dir" = "true" ]]; then
    popd >/dev/null
  fi
done

if [[ -n "$post_compile" ]]; then
  info "Run post compile commands"
  eval "$post_compile"
fi

exit "$exit_code"
