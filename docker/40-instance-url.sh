#!/bin/sh
# Writes the web client's target hint. INSTANCE_URL is optional and is read
# when the already built image starts, for example via --env-file.
set -eu
dest=/usr/share/nginx/html/instance-config.json
url=${INSTANCE_URL-}
escaped=$(printf '%s' "$url" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"instanceUrl":"%s"}\n' "$escaped" > "$dest"
