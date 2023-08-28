#!/usr/bin/env bash

set -eo pipefail

run() {
  echo -e "\033[1;34m$@\033[0m"
  "$@"
}

error() {
  echo "::error :: $1"
  exit 1
}

texlive_version="${1}"
docker_image="${2}"
shift 2

if [[ -n "$texlive_version" && -n "$docker_image" ]]; then
  error "Input 'texlive_version' and 'docker_image' cannot co-exist".
fi

if [[ -z "$docker_image" ]]; then
  case "$texlive_version" in
  "" | "latest" | "2023")
    image_version="latest"
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
    error "TeX Live version $texlive_version is not supported. The currently supported versions are 2020-2023 or latest."
    ;;
  esac
  docker_image="ghcr.io/xu-cheng/texlive-full:$image_version"
fi

run docker run --rm \
  -e "TEXINPUTS" \
  -e "HOME" \
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
  "$docker_image" \
  "$@"
