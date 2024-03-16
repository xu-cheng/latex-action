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

# install git on old images
if ! command -v git &>/dev/null; then
  apk --no-cache add git
fi
git config --system --add safe.directory "$GITHUB_WORKSPACE"

if [[ -z "$INPUT_ROOT_FILE" ]]; then
  error "Input 'root_file' is missing."
fi

readarray -t root_file <<<"$INPUT_ROOT_FILE"

if [[ -n "$INPUT_WORKING_DIRECTORY" ]]; then
  if [[ ! -d "$INPUT_WORKING_DIRECTORY" ]]; then
    mkdir -p "$INPUT_WORKING_DIRECTORY"
  fi
  cd "$INPUT_WORKING_DIRECTORY"
fi

expanded_root_file=()
for pattern in "${root_file[@]}"; do
  # shellcheck disable=SC2206
  expanded=($pattern)
  expanded_root_file+=("${expanded[@]}")
done
root_file=("${expanded_root_file[@]}")

if [[ -z "$INPUT_COMPILER" && -z "$INPUT_ARGS" ]]; then
  warn "Input 'compiler' and 'args' are both empty. Reset them to default values."
  INPUT_COMPILER="latexmk"
  INPUT_ARGS="-pdf -file-line-error -halt-on-error -interaction=nonstopmode"
fi

IFS=' ' read -r -a args <<<"$INPUT_ARGS"

if [[ "$INPUT_COMPILER" = "latexmk" ]]; then
  if [[ "$INPUT_LATEXMK_SHELL_ESCAPE" = "true" ]]; then
    args+=("-shell-escape")
  fi

  if [[ "$INPUT_LATEXMK_USE_LUALATEX" = "true" && "$INPUT_LATEXMK_USE_XELATEX" = "true" ]]; then
    error "Input 'latexmk_use_lualatex' and 'latexmk_use_xelatex' cannot be used at the same time."
  fi

  if [[ "$INPUT_LATEXMK_USE_LUALATEX" = "true" ]]; then
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

  if [[ "$INPUT_LATEXMK_USE_XELATEX" = "true" ]]; then
    for i in "${!args[@]}"; do
      if [[ "${args[i]}" = "-pdf" ]]; then
        unset 'args[i]'
      fi
    done
    args+=("-xelatex")
  fi
else
  for VAR in "${!INPUT_LATEXMK_@}"; do
    if [[ "${!VAR}" = "true" ]]; then
      error "Input '${VAR}' is only valid if input 'compiler' is set to 'latexmk'."
    fi
  done
fi

if [[ -n "$INPUT_EXTRA_SYSTEM_PACKAGES" ]]; then
  IFS=$' \t\n'
  for pkg in $INPUT_EXTRA_SYSTEM_PACKAGES; do
    info "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [[ -n "$INPUT_EXTRA_FONTS" ]]; then
  readarray -t extra_fonts <<<"$INPUT_EXTRA_FONTS"
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

if [[ -n "$INPUT_TLMGR_REPO" && "$INPUT_TLMGR_REPO" != latest ]]; then
  tlmgr_repo_url="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/$INPUT_TLMGR_REPO/tlnet-final"
  info "Set tlmgr repo to $tlmgr_repo_url"
  tlmgr option repository "$tlmgr_repo_url"
fi

if [[ -n "$INPUT_PRE_COMPILE" ]]; then
  info "Run pre compile commands"
  eval "$INPUT_PRE_COMPILE"
fi

exit_code=0

for f in "${root_file[@]}"; do
  if [[ -z "$f" ]]; then
    continue
  fi

  if [[ "$INPUT_WORK_IN_ROOT_FILE_DIR" = "true" ]]; then
    pushd "$(dirname "$f")" >/dev/null
    f="$(basename "$f")"
    info "Compile $f in $PWD"
  else
    info "Compile $f"
  fi

  if [[ ! -f "$f" ]]; then
    error "File '$f' cannot be found from the directory '$PWD'."
  fi

  "$INPUT_COMPILER" "${args[@]}" "$f" || ret="$?"
  if [[ "$ret" -ne 0 ]]; then
    if [[ "$INPUT_CONTINUE_ON_ERROR" = "true" ]]; then
      exit_code="$ret"
    else
      exit "$ret"
    fi
  fi

  if [[ "$INPUT_WORK_IN_ROOT_FILE_DIR" = "true" ]]; then
    popd >/dev/null
  fi
done

if [[ -n "$INPUT_POST_COMPILE" ]]; then
  info "Run post compile commands"
  eval "$INPUT_POST_COMPILE"
fi

exit "$exit_code"
