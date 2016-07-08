#!/bin/sh
set -e

while read URL; do
    tput bold
    echo "$URL"
    tput sgr0
    curl -sS --head -w '%{http_code}  %{redirect_url}\n' -o /dev/null "$URL"
    echo
done
