#!/usr/bin/env bash

set -eo pipefail

random_token() {
  tr -dc A-Za-z0-9 </dev/urandom 2>/dev/null | head -c 32
  echo ""
}

run() {
  token="$(random_token)"
  echo "::stop-commands::${token}"
  echo -e "\033[1;34m${*@Q}\033[0m"
  echo "::${token}::"
  "$@"
}

error() {
  echo "::error :: $1"
  exit 1
}

if [[ -n "$INPUT_TEXLIVE_VERSION" && -n "$INPUT_DOCKER_IMAGE" ]]; then
  error "Input 'texlive_version' and 'docker_image' cannot co-exist".
fi

export INPUT_TLMGR_REPO=""

if [[ -z "$INPUT_DOCKER_IMAGE" ]]; then
  INPUT_TLMGR_REPO="$INPUT_TEXLIVE_VERSION"
  case "$INPUT_TEXLIVE_VERSION" in
  "" | "latest" | "2024")
    image_version="latest"
    INPUT_TLMGR_REPO="latest"
    ;;
  "2023")
    image_version="20240301"
    ;;
  "2022")
    image_version="20230301"
    ;;
  "2021")
    image_version="20220201"
    ;;
  "2020")
    image_version="20210301"
    ;;
  *)
    error "TeX Live version $INPUT_TEXLIVE_VERSION is not supported. The currently supported versions are 2020-2024 or latest."
    ;;
  esac
  INPUT_DOCKER_IMAGE="ghcr.io/xu-cheng/texlive-full:$image_version"
fi

# ref: https://docs.miktex.org/manual/envvars.html
run docker run --rm \
  -e "BIBINPUTS" \
  -e "BSTINPUTS" \
  -e "MFINPUTS" \
  -e "TEXINPUTS" \
  -e "TFMFONTS" \
  -e "HOME" \
  -e "INPUT_ROOT_FILE" \
  -e "INPUT_WORKING_DIRECTORY" \
  -e "INPUT_WORK_IN_ROOT_FILE_DIR" \
  -e "INPUT_CONTINUE_ON_ERROR" \
  -e "INPUT_COMPILER" \
  -e "INPUT_ARGS" \
  -e "INPUT_EXTRA_SYSTEM_PACKAGES" \
  -e "INPUT_EXTRA_FONTS" \
  -e "INPUT_PRE_COMPILE" \
  -e "INPUT_POST_COMPILE" \
  -e "INPUT_LATEXMK_SHELL_ESCAPE" \
  -e "INPUT_LATEXMK_USE_LUALATEX" \
  -e "INPUT_LATEXMK_USE_XELATEX" \
  -e "INPUT_TLMGR_REPO" \
  -e "GITHUB_JOB" \
  -e "GITHUB_REF" \
  -e "GITHUB_SHA" \
  -e "GITHUB_REPOSITORY" \
  -e "GITHUB_REPOSITORY_OWNER" \
  -e "GITHUB_REPOSITORY_OWNER_ID" \
  -e "GITHUB_RUN_ID" \
  -e "GITHUB_RUN_NUMBER" \
  -e "GITHUB_RETENTION_DAYS" \
  -e "GITHUB_RUN_ATTEMPT" \
  -e "GITHUB_REPOSITORY_ID" \
  -e "GITHUB_ACTOR_ID" \
  -e "GITHUB_ACTOR" \
  -e "GITHUB_TRIGGERING_ACTOR" \
  -e "GITHUB_WORKFLOW" \
  -e "GITHUB_HEAD_REF" \
  -e "GITHUB_BASE_REF" \
  -e "GITHUB_EVENT_NAME" \
  -e "GITHUB_SERVER_URL" \
  -e "GITHUB_API_URL" \
  -e "GITHUB_GRAPHQL_URL" \
  -e "GITHUB_REF_NAME" \
  -e "GITHUB_REF_PROTECTED" \
  -e "GITHUB_REF_TYPE" \
  -e "GITHUB_WORKFLOW_REF" \
  -e "GITHUB_WORKFLOW_SHA" \
  -e "GITHUB_WORKSPACE" \
  -e "GITHUB_ACTION" \
  -e "GITHUB_EVENT_PATH" \
  -e "GITHUB_ACTION_REPOSITORY" \
  -e "GITHUB_ACTION_REF" \
  -e "GITHUB_PATH" \
  -e "GITHUB_ENV" \
  -e "GITHUB_STEP_SUMMARY" \
  -e "GITHUB_STATE" \
  -e "GITHUB_OUTPUT" \
  -e "RUNNER_OS" \
  -e "RUNNER_ARCH" \
  -e "RUNNER_NAME" \
  -e "RUNNER_ENVIRONMENT" \
  -e "RUNNER_TOOL_CACHE" \
  -e "RUNNER_TEMP" \
  -e "RUNNER_WORKSPACE" \
  -e "ACTIONS_RUNTIME_URL" \
  -e "ACTIONS_RUNTIME_TOKEN" \
  -e "ACTIONS_CACHE_URL" \
  -e GITHUB_ACTIONS=true \
  -e CI=true \
  -v "/var/run/docker.sock":"/var/run/docker.sock" \
  -v "$HOME:$HOME" \
  -v "$GITHUB_ENV:$GITHUB_ENV" \
  -v "$GITHUB_OUTPUT:$GITHUB_OUTPUT" \
  -v "$GITHUB_STEP_SUMMARY:$GITHUB_STEP_SUMMARY" \
  -v "$GITHUB_PATH:$GITHUB_PATH" \
  -v "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" \
  -v "$GITHUB_ACTION_PATH/entrypoint.sh":/entrypoint.sh \
  -w "$GITHUB_WORKSPACE" \
  --entrypoint "/entrypoint.sh" \
  "$INPUT_DOCKER_IMAGE"
