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

if [[ "$INPUT_OS" != "alpine" && "$INPUT_OS" != "debian" ]]; then
  error "Input 'os' can only be either 'alpine' or 'debian'".
fi

if [[ -z "$INPUT_DOCKER_IMAGE" ]]; then
  case "$INPUT_TEXLIVE_VERSION" in
    "" | "latest" | "2025")
      if [[ "$INPUT_OS" = "alpine" ]]; then
        INPUT_DOCKER_IMAGE="ghcr.io/xu-cheng/texlive-alpine:latest"
      else
        INPUT_DOCKER_IMAGE="ghcr.io/xu-cheng/texlive-debian:latest"
      fi
      ;;
    "2020" | "2021" | "2022" | "2023" | "2024")
      if [[ "$INPUT_OS" = "alpine" ]]; then
        INPUT_DOCKER_IMAGE="ghcr.io/xu-cheng/texlive-historic-alpine:$INPUT_TEXLIVE_VERSION"
      else
        INPUT_DOCKER_IMAGE="ghcr.io/xu-cheng/texlive-historic-debian:$INPUT_TEXLIVE_VERSION"
      fi
      ;;
    *)
      error "TeX Live version $INPUT_TEXLIVE_VERSION is not supported. The currently supported versions are 2020-2025 or latest."
      ;;
  esac
fi

# ref: https://docs.miktex.org/manual/envvars.html
run docker run --rm \
  -e "BIBINPUTS" \
  -e "BSTINPUTS" \
  -e "MFINPUTS" \
  -e "TEXINPUTS" \
  -e "TFMFONTS" \
  -e "HOME" \
  -e "INPUT_ARGS" \
  -e "INPUT_COMPILER" \
  -e "INPUT_CONTINUE_ON_ERROR" \
  -e "INPUT_EXTRA_FONTS" \
  -e "INPUT_EXTRA_SYSTEM_PACKAGES" \
  -e "INPUT_LATEXMK_SHELL_ESCAPE" \
  -e "INPUT_LATEXMK_USE_LUALATEX" \
  -e "INPUT_LATEXMK_USE_XELATEX" \
  -e "INPUT_POST_COMPILE" \
  -e "INPUT_PRE_COMPILE" \
  -e "INPUT_ROOT_FILE" \
  -e "INPUT_WORKING_DIRECTORY" \
  -e "INPUT_WORK_IN_ROOT_FILE_DIR" \
  -e "GITHUB_ACTION" \
  -e "GITHUB_ACTION_REF" \
  -e "GITHUB_ACTION_REPOSITORY" \
  -e "GITHUB_ACTOR" \
  -e "GITHUB_ACTOR_ID" \
  -e "GITHUB_API_URL" \
  -e "GITHUB_BASE_REF" \
  -e "GITHUB_ENV" \
  -e "GITHUB_EVENT_NAME" \
  -e "GITHUB_EVENT_PATH" \
  -e "GITHUB_GRAPHQL_URL" \
  -e "GITHUB_HEAD_REF" \
  -e "GITHUB_JOB" \
  -e "GITHUB_OUTPUT" \
  -e "GITHUB_PATH" \
  -e "GITHUB_REF" \
  -e "GITHUB_REF_NAME" \
  -e "GITHUB_REF_PROTECTED" \
  -e "GITHUB_REF_TYPE" \
  -e "GITHUB_REPOSITORY" \
  -e "GITHUB_REPOSITORY_ID" \
  -e "GITHUB_REPOSITORY_OWNER" \
  -e "GITHUB_REPOSITORY_OWNER_ID" \
  -e "GITHUB_RETENTION_DAYS" \
  -e "GITHUB_RUN_ATTEMPT" \
  -e "GITHUB_RUN_ID" \
  -e "GITHUB_RUN_NUMBER" \
  -e "GITHUB_SERVER_URL" \
  -e "GITHUB_SHA" \
  -e "GITHUB_STATE" \
  -e "GITHUB_STEP_SUMMARY" \
  -e "GITHUB_TRIGGERING_ACTOR" \
  -e "GITHUB_WORKFLOW" \
  -e "GITHUB_WORKFLOW_REF" \
  -e "GITHUB_WORKFLOW_SHA" \
  -e "GITHUB_WORKSPACE" \
  -e "RUNNER_ARCH" \
  -e "RUNNER_ENVIRONMENT" \
  -e "RUNNER_NAME" \
  -e "RUNNER_OS" \
  -e "RUNNER_TEMP" \
  -e "RUNNER_TOOL_CACHE" \
  -e "RUNNER_WORKSPACE" \
  -e "ACTIONS_CACHE_URL" \
  -e "ACTIONS_RUNTIME_TOKEN" \
  -e "ACTIONS_RUNTIME_URL" \
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
