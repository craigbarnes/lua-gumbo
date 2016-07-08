#!/bin/sh
set -e

while read URL; do
    curl -sS --head -w " %{http_code}  $URL  %{redirect_url}\n" -o /dev/null "$URL"
done
