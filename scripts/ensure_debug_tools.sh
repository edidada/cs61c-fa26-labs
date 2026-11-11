#!/usr/bin/env bash
set -euo pipefail
if command -v gdb && command -v valgrind; then
    gdb --version | head -1
    valgrind --version
    exit 0
fi
# sudo normally removes proxy variables; preserve the runner's HTTP proxy without printing its value.
proxy_url=${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-}}}}
if [[ -n "$proxy_url" ]]; then
    export http_proxy="$proxy_url" https_proxy="$proxy_url"
    echo 'Using configured runner HTTP proxy for apt'
else
    echo 'No HTTP proxy configured for apt'
fi
# Use an isolated source list; the runner's Azure mirror failed DNS in run 43038273993.
source_list=$(mktemp)
for suite in noble noble-updates noble-security; do
    printf 'deb [signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg] https://archive.ubuntu.com/ubuntu %s main universe\n' "$suite" >> "$source_list"
done
options=(-o "Dir::Etc::sourcelist=$source_list" -o 'Dir::Etc::sourceparts=-' -o Acquire::Retries=1 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20)
sudo --preserve-env=http_proxy,https_proxy timeout 180 apt-get "${options[@]}" -o APT::Update::Error-Mode=any update
sudo --preserve-env=http_proxy,https_proxy timeout 180 apt-get "${options[@]}" install -y gdb valgrind
