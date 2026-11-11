#!/bin/sh
# Fills the link-preview tags of index.html with the public address of the
# client. A preview needs an absolute address, and the build does not know it.
# The client is served at the root of the host that INSTANCE_URL names, so the
# address is that origin. Without it the image stays a relative path and the
# og:url tag is dropped.
set -eu
html=/usr/share/nginx/html/index.html
template=/usr/share/nginx/index.html.template
[ -f "$template" ] || cp "$html" "$template"
origin=$(printf '%s' "${INSTANCE_URL-}" \
  | sed -nE 's#^(https?://[A-Za-z0-9.-]+(:[0-9]+)?)(/.*)?$#\1#p')
if [ -n "$origin" ]; then
  sed "s|%SELF_URI%|$origin/|g" "$template" > "$html"
else
  sed -e '/property="og:url"/d' -e 's|%SELF_URI%||g' "$template" > "$html"
fi
