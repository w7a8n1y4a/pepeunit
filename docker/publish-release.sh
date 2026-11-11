#!/usr/bin/env bash
# Immutable tag packages and GitLab Release links. Requires curl, jq, sha256sum.
set -euo pipefail
: "${CI_API_V4_URL:?}" "${CI_PROJECT_ID:?}" "${CI_COMMIT_TAG:?}" "${CI_ACCESS_TOKEN:?}"
for tool in curl jq sha256sum; do command -v "$tool" >/dev/null || { echo "Required command: $tool" >&2; exit 1; }; done

mode=release
group=
directory=build/release
while (($#)); do
  case "$1" in
    --check|--upload) mode=${1#--}; group=${2:?Missing platform}; shift 2 ;;
    --directory) directory=${2:?Missing directory}; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
linux=("pepeunit-${CI_COMMIT_TAG}-linux-amd64.tar.gz")
android=("pepeunit-${CI_COMMIT_TAG}-android-arm64-v8a.apk")
files=("${linux[@]}" "${android[@]}")
if [[ "$mode" != release ]]; then
  case "$group" in
    linux) files=("${linux[@]}") ;;
    android) files=("${android[@]}") ;;
    *) echo "Unknown platform: $group" >&2; exit 2 ;;
  esac
fi
# GitLab behind a TLS proxy may advertise an http CI_API_V4_URL. Use HTTPS
# before sending credentials or PUT/POST bodies; redirects are not upload URLs.
# Override explicitly for installations that intentionally use plain HTTP.
api=${RELEASE_API_V4_URL:-${CI_API_V4_URL/#http:/https:}}
project="${api%/}/projects/$(jq -rn --arg value "$CI_PROJECT_ID" '$value|@uri')"
tag=$(jq -rn --arg value "$CI_COMMIT_TAG" '$value|@uri')
package="$project/packages/generic/pepeunit-client/$tag"
release="$project/releases/$tag"
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Keep the token out of process arguments. curl config requires escaped quotes/backslashes.
token=${CI_ACCESS_TOKEN//\\/\\\\}
token=${token//\"/\\\"}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || { echo "Invalid token" >&2; exit 1; }

# Response body is reused between requests, so at most one downloaded binary is kept.
# Return 3 only for a missing file; auth/network/server failures must stop the job.
request() {
  local method=$1 url=$2 status location
  local -a head_args=()
  shift 2
  if [[ "$method" == HEAD ]]; then head_args=(--head); fi
  status=$(printf 'header = "PRIVATE-TOKEN: %s"\n' "$token" | curl --config - \
    --silent --show-error --connect-timeout 30 --max-time 1800 \
    "${head_args[@]}" --request "$method" --output "$temporary/response" --dump-header "$temporary/headers" \
    --write-out '%{http_code}' "$@" "$url") || return 1
  # Some proxies reject HEAD; signed object-storage links may allow GET only.
  if [[ "$method" == HEAD && ( "$status" =~ ^30[12378]$ || "$status" == 405 || "$status" == 501 ) ]]; then
    return 4
  fi
  if [[ "$method" == GET && "$status" =~ ^30[12378]$ ]]; then
    # Generic Packages can redirect to signed object-storage URLs. Never forward the token.
    location=$(sed -n 's/^[Ll]ocation: *//p' "$temporary/headers" | tr -d '\r' | tail -n 1)
    [[ "$location" == https://* || "$location" == http://* ]] || { echo "Invalid package redirect" >&2; return 1; }
    status=$(curl --silent --show-error "${head_args[@]}" --location --max-redirs 5 \
      --connect-timeout 30 --max-time 1800 --dump-header "$temporary/headers" --output "$temporary/response" \
      --write-out '%{http_code}' "$location") || return 1
  fi
  case "$status" in
    2??) return 0 ;;
    404) return 3 ;;
    *) echo "GitLab request failed: $method $url (HTTP $status)" >&2; return 1 ;;
  esac
}
# Presence probes avoid downloading APKs/archives just to skip a rebuild.
# Downloads are still checksummed after upload and before publishing a release.
exists() {
  local status length
  if request HEAD "$package/$1"; then
    :
  else
    status=$?
    if ((status == 4)); then digest "$1" >/dev/null; return $?; fi
    return "$status"
  fi
  length=$(sed -n 's/^[Cc]ontent-[Ll]ength: *//p' "$temporary/headers" | tr -d '\r' | tail -n 1)
  [[ "$length" != 0 ]] || { echo "Empty package file: $1" >&2; return 1; }
}
digest() {
  request GET "$package/$1" || return $?
  [[ -s "$temporary/response" ]] || { echo "Empty package file: $1" >&2; return 1; }
  sha256sum "$temporary/response" | cut -d ' ' -f 1
}
upload() {
  request PUT "$package/$1" --upload-file "$2"
}

if [[ "$mode" == check ]]; then
  for file in "${files[@]}"; do exists "$file" || exit $?; done
  exit 0
fi
if [[ "$mode" == upload ]]; then
  for file in "${files[@]}"; do
    if exists "$file"; then
      # Archives/APKs can differ after a rebuild: the first published bytes win.
      echo "Keeping published file: $file"
      continue
    else
      status=$?
      ((status == 3)) || exit "$status"
    fi
    [[ -s "$directory/$file" ]] || { echo "Missing or empty release artifact: $directory/$file" >&2; exit 1; }
    expected=$(sha256sum "$directory/$file" | cut -d ' ' -f 1)
    upload "$file" "$directory/$file"
    actual=$(digest "$file")
    [[ "$actual" == "$expected" ]] || { echo "Uploaded checksum mismatch: $file" >&2; exit 1; }
  done
  exit 0
fi

: "${HUB_IMAGE:?}"
for file in "${files[@]}"; do
  if checksum=$(digest "$file"); then
    printf '%s  %s\n' "$checksum" "$file" >> "$temporary/SHA256SUMS"
  else
    echo "Package unavailable; release not published: $file" >&2
    exit 1
  fi
done
expected=$(sha256sum "$temporary/SHA256SUMS" | cut -d ' ' -f 1)
if actual=$(digest SHA256SUMS); then
  [[ "$actual" == "$expected" ]] || { echo "Published SHA256SUMS conflicts with package contents" >&2; exit 1; }
else
  status=$?
  ((status == 3)) || exit "$status"
  upload SHA256SUMS "$temporary/SHA256SUMS"
  actual=$(digest SHA256SUMS)
  [[ "$actual" == "$expected" ]] || { echo "Uploaded SHA256SUMS mismatch" >&2; exit 1; }
fi
links=$(printf '%s\n' "${files[@]}" SHA256SUMS | jq -Rsc --arg base "$package" \
  'split("\n")[:-1] | map({name: ., url: ($base + "/" + .), link_type: "package"})')
metadata=$(jq -n --arg name "Release Tag - $CI_COMMIT_TAG" \
  --arg description "Native downloads below. Web image: [Docker Hub](https://hub.docker.com/r/$HUB_IMAGE/tags)." \
  '{name: $name, description: $description}')
if request GET "$release"; then
  request PUT "$release" --header 'Content-Type: application/json' --data "$metadata"
  # Release updates do not reconcile asset links; fetch all pages before updating them.
  current='[]'
  page=1
  while :; do
    request GET "$release/assets/links?per_page=100&page=$page"
    batch=$(jq -ce 'if type == "array" then . else error("Expected asset links array") end' "$temporary/response")
    current=$(jq -cn --argjson left "$current" --argjson right "$batch" '$left + $right')
    [[ $(jq length <<< "$batch") -eq 100 ]] || break
    page=$((page + 1))
  done
  while IFS= read -r desired; do
    name=$(jq -r .name <<< "$desired")
    existing=$(jq -c --arg name "$name" 'map(select(.name == $name))[0] // empty' <<< "$current")
    if [[ -z "$existing" ]]; then
      request POST "$release/assets/links" --header 'Content-Type: application/json' --data "$desired"
    elif ! jq -e --argjson desired "$desired" \
      '.name == $desired.name and .url == $desired.url and .link_type == $desired.link_type' <<< "$existing" >/dev/null; then
      id=$(jq -r .id <<< "$existing")
      request PUT "$release/assets/links/$id" --header 'Content-Type: application/json' --data "$desired"
    fi
  done < <(jq -c '.[]' <<< "$links")
else
  status=$?
  ((status == 3)) || exit "$status"
  payload=$(jq -c --arg tag "$CI_COMMIT_TAG" --argjson links "$links" \
    '. + {tag_name: $tag, assets: {links: $links}}' <<< "$metadata")
  request POST "$project/releases" --header 'Content-Type: application/json' --data "$payload"
fi
echo "Release ready: $CI_COMMIT_TAG"
