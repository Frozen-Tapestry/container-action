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
    --username="$USERNAME"
    --password="$PASSWORD"
  )
  run_cmd "${build_cmd[@]}"
fi

# Function that splits on unescaped spaces (but not on escaped ones)
# and outputs each processed token on a new line.
generate_args() {
  local input_args="$1"
  local prefix="$2"
  local output=()
  local placeholder="__ESCAPED_SPACE__"

  if [[ -n "$input_args" ]]; then
    # Replace escaped spaces (\ ) with a unique placeholder.
    local temp="${input_args//\\ /$placeholder}"
    # Split on spaces (escaped ones are now hidden).
    IFS=' ' read -r -a parts <<< "$temp"
    for part in "${parts[@]}"; do
      # Skip any empty parts.
      [[ -z "$part" ]] && continue
      # Restore escaped spaces.
      part="${part//$placeholder/ }"
      output+=("$prefix$part")
    done
  fi

  printf "%s\n" "${output[@]}"
}

### BUILD
if [[ -n "$DOCKERFILE" ]]; then
  CREATED="$(date '+%Y-%m-%dT%T')"
  REVISION="$REVISION"
  SOURCE="$SOURCE"

  echo "Main labels: $CREATED $REVISION $SOURCE"

  TAGS=$(generate_args "$ACTION_TAGS" "-t=")
  echo "Tags: ${TAGS[@]}"
  LABELS=$(generate_args "$ACTION_LABELS" "--label=")
  echo "Labels: ${LABELS[@]}"
  BUILD_ARGS=$(generate_args "$ACTION_BUILD_ARGS" "--build-arg=")
  echo "Build args: ${BUILD_ARGS[@]}"
  EXTRA_ARGS=$(generate_args "$ACTION_EXTRA_ARGS" "")
  echo "Extra args: ${EXTRA_ARGS[@]}"

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
  echo "Tags: ${TAGS[@]}"

  for tag in $TAGS
  do
    build_cmd=(podman push
      --storage-driver=overlay
      --authfile="$REGISTRY_AUTH_FILE"
      $tag
    )
    run_cmd "${build_cmd[@]}"
  done
fi
