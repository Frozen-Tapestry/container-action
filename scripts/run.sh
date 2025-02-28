#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

REGISTRY=${REGISTRY:-}
USERNAME=${USERNAME:-}
PASSWORD=${PASSWORD:-}
DOCKERFILE=${DOCKERFILE:-}
PUSH=${PUSH:-}

PODMAN_USER="podman"

chown $PODMAN_USER:$PODMAN_USER /home/$PODMAN_USER/auth
chown $PODMAN_USER:$PODMAN_USER /home/$PODMAN_USER/.local/share/containers/storage

run_cmd() {
    local build_cmd=("$@")
    cmd=$(printf "%q\t" "${build_cmd[@]}")
    echo "Running: $cmd"
    su "$PODMAN_USER" -c "$cmd"
}

### LOGIN
if [[ -n "$REGISTRY" && -n "$USERNAME" && -n "$PASSWORD" ]]; then
  build_cmd=(podman login
    --storage-driver=overlay
    --authfile="$REGISTRY_AUTH_FILE"
    "$REGISTRY"
    -username="$USERNAME"
    --password="$PASSWORD"
  )
  run_cmd "${build_cmd[@]}"
fi

generate_args() {
  local input_args="$1"
  local prefix="$2"
  local output=""

  if [[ -n "$input_args" ]]; then
    output="$(echo "$input_args" | tr -s ' ' '\n' | sed "s/[^ ]* */$prefix&/g")"
  fi

  echo "$output"
}

### BUILD
if [[ -n "$DOCKERFILE" ]]; then
  CREATED="$(date '+%Y-%m-%dT%T')"
  REVISION="$REVISION"
  SOURCE="$SOURCE"

  echo "Main labels: $CREATED $REVISION $SOURCE"

  TAGS=$(generate_args "$ACTION_TAGS" "-t=")
  echo "Tags: $TAGS"
  LABELS=$(generate_args "$ACTION_LABELS" "--label=")
  echo "Labels: $LABELS"
  BUILD_ARGS=$(generate_args "$ACTION_BUILD_ARGS" "--build-arg=")
  echo "Build args: $BUILD_ARGS"
  EXTRA_ARGS=$(generate_args "$ACTION_EXTRA_ARGS" "")
  echo "Extra args: $EXTRA_ARGS"

  build_cmd=(podman build
    --platform="linux/amd64"
    --storage-driver=overlay
    --authfile="$REGISTRY_AUTH_FILE"
    --pull=true
    --label=image.created="$CREATED"
    --label=image.revision="$REVISION"
    --label=image.source="$SOURCE"
    $TAGS
    $LABELS
    $BUILD_ARGS
    $EXTRA_ARGS
    --file="$DOCKERFILE"
    .
  )
  run_cmd "${build_cmd[@]}"
fi

if [[ -n "$PUSH" && "$PUSH" == "true" ]]; then
  TAGS=$(generate_args "$ACTION_TAGS" "")
  echo "Tags: $TAGS"

  build_cmd=(podman push
    --storage-driver=overlay
    --authfile="$REGISTRY_AUTH_FILE" $TAGS
  )
  run_cmd "${build_cmd[@]}"
fi