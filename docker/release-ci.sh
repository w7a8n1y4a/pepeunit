#!/usr/bin/env bash
# CI-only lifecycle. Never prune resources belonging to another job.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CI_JOB_ID:?}" "${CI_PROJECT_DIR:?}"
target=${1:?linux, android, web or cleanup}
DOCKER=${DOCKER:-docker}
builder="pepeunit-release-${CI_JOB_ID}"
workspace="$CI_PROJECT_DIR/build/release-ci-${CI_JOB_ID}"
export RELEASE_DIR="$workspace/output"

cleanup() {
  local failed=0
  if [[ -f "$workspace/builder-started" ]]; then
    "$DOCKER" buildx rm -f "$builder" || failed=1
  fi
  if ((failed == 0)); then rm -rf -- "$workspace"; fi
  return "$failed"
}
if [[ "$target" == cleanup ]]; then cleanup; exit; fi
finish() {
  local status=$?
  trap - EXIT
  if ! cleanup; then
    echo "Release cleanup failed; after_script will retry." >&2
    if ((status == 0)); then status=1; fi
  fi
  exit "$status"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$RELEASE_DIR"
if [[ "$target" != web ]]; then
  if bash docker/publish-release.sh --check "$target"; then
    echo "All $target packages already published; skipping rebuild."
    exit 0
  else
    status=$?
    if ((status != 3)); then exit "$status"; fi
  fi
fi
touch "$workspace/builder-started"
"$DOCKER" buildx create --name "$builder" --driver docker-container --driver-opt env.GODEBUG=tlsmlkem=0
"$DOCKER" buildx inspect "$builder" --bootstrap
args=(--builder "$builder" --build-arg "INSTANCE_URL=${INSTANCE_URL:-}")
case "$target" in
  linux)
    args+=(-f docker/release.Dockerfile --target linux --platform linux/amd64,linux/arm64
      --output "type=local,dest=$RELEASE_DIR,platform-split=false") ;;
  android)
    : "${ANDROID_KEYSTORE_PASSWORD:?}" "${ANDROID_KEY_PASSWORD:?}" "${ANDROID_KEY_ALIAS:?}"
    if [[ -z "${ANDROID_KEYSTORE_FILE:-}" ]]; then
      : "${ANDROID_KEYSTORE_BASE64:?Set ANDROID_KEYSTORE_BASE64 or ANDROID_KEYSTORE_FILE}"
      ANDROID_KEYSTORE_FILE="$workspace/android-release.keystore"
      (umask 077; printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$ANDROID_KEYSTORE_FILE")
    fi
    if [[ ! -s "$ANDROID_KEYSTORE_FILE" ]]; then
      echo "Android release keystore is missing or empty." >&2
      exit 1
    fi
    args+=(-f docker/release.Dockerfile --target android --platform linux/amd64
      --build-arg "BUILD_NUMBER=${CI_PIPELINE_IID:?}"
      --secret "id=android_keystore,src=$ANDROID_KEYSTORE_FILE"
      --secret id=android_store_password,env=ANDROID_KEYSTORE_PASSWORD
      --secret id=android_key_password,env=ANDROID_KEY_PASSWORD
      --secret id=android_key_alias,env=ANDROID_KEY_ALIAS
      --output "type=local,dest=$RELEASE_DIR") ;;
  web)
    args+=(--platform linux/amd64,linux/arm64 --provenance=false --sbom=false
      -t "${HUB_IMAGE:?}:${CI_COMMIT_TAG:?}" --push) ;;
  *) echo "Unknown release target: $target" >&2; exit 2 ;;
esac
"$DOCKER" buildx build "${args[@]}" .
if [[ "$target" != web ]]; then
  bash docker/publish-release.sh --upload "$target" --directory "$RELEASE_DIR"
fi
