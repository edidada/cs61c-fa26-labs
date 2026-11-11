#!/usr/bin/env bash
set -euo pipefail
if command -v gdb && command -v valgrind; then
    gdb --version | head -1
    valgrind --version
    if ! dpkg-query -W -f='${Status}' libc6-dbg 2>/dev/null | grep -q 'install ok installed'; then
        version=$(dpkg-query -W -f='${Version}' libc6:amd64)
        echo "Installing matching glibc debug symbols for $version"
        deb=$(mktemp --suffix=.deb)
        url="https://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dbg_${version}_amd64.deb"
        if ! curl --fail --location --connect-timeout 10 --max-time 90 "$url" -o "$deb"; then
            # Official archive A records verified on 2026-11-12. Keep hostname/TLS
            # verification intact when the runner cannot resolve Ubuntu DNS.
            downloaded=false
            for address in 185.125.190.83 91.189.91.82 91.189.92.23; do
                if curl --fail --location --resolve "archive.ubuntu.com:443:$address" --connect-timeout 10 --max-time 90 "$url" -o "$deb"; then
                    downloaded=true
                    break
                fi
            done
            "$downloaded"
        fi
        sudo dpkg -i "$deb"
    fi
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
