#!/bin/sh
# Copyright © 2019 Nathan Dorfman <ndorf@rtfm.net>

case "$1" in
    --pull|-p)
        shift
        docker pull "$1" || exit 2
        ;;
esac

if [ "$#" -gt 2 -o "$#" -lt 1 -o "${1#-}" != "$1" ]; then
    echo "Usage: $0 [--pull|-p] <tag> [http://<proxy>:<port>/...]" >&2
    exit 1
elif [ "$#" -gt 1 ]; then
    proxy_url="$2"
else
    proxy_url='http://172.17.0.1:3142/'
fi

set -e
temp_dir=$(mktemp -d)
cd "$temp_dir"

cat > Dockerfile << EOF
FROM $1

RUN echo "Acquire::http::Proxy \"${proxy_url}\";" > /etc/apt/apt.conf.d/99proxy
EOF

docker build --tag "$1" .

echo Created "$1" using apt proxy "$proxy_url".
cd || cd /
rm "$temp_dir"/Dockerfile
rmdir "$temp_dir"
