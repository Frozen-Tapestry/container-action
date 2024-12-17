#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

REGISTRY=${REGISTRY:-}
USERNAME=${USERNAME:-}
PASSWORD=${PASSWORD:-}
DOCKERFILE=${DOCKERFILE:-}
PUSH=${PUSH:-}

### LOGIN
if [[ -n "$REGISTRY" && -n "$USERNAME" && -n "$PASSWORD" ]]; then
  podman login --storage-driver=overlay "$REGISTRY" -u "$USERNAME" -p "$PASSWORD"
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

  podman build --platform="linux/amd64" \
    --storage-driver=overlay \
    --pull=true \
    --label image.created="$CREATED" \
    --label image.revision="$REVISION" \
    --label image.source="$SOURCE" \
    $TAGS \
    $LABELS \
    $BUILD_ARGS \
    $EXTRA_ARGS \
    -f "$DOCKERFILE" \
    .
fi

if [[ -n "$PUSH" && "$PUSH" == "true" ]]; then
  TAGS=$(generate_args "$ACTION_TAGS" "")
  echo "Tags: $TAGS"

  podman push --storage-driver=overlay $TAGS
fi