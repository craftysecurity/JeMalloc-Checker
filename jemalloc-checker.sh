#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get jemalloc version from symbols
get_jemalloc_version() {
    local libc_path="$1"
    local version=""

    # Check if readelf exists, otherwise use objdump
    if command_exists readelf; then
        symbols=$(readelf -sW "$libc_path" 2>/dev/null)
    elif command_exists objdump; then
        symbols=$(objdump -T "$libc_path" 2>/dev/null)
    else
        echo "Error: Neither readelf nor objdump found. Cannot proceed."
        exit 1
    fi

    # Check for jemalloc 5+ specific symbols to detect old version
    if echo "$symbols" | grep -q "je_malloc_stats_print"; then
        version="5 or later"
    # Check for older jemalloc symbols
    elif echo "$symbols" | grep -q "je_malloc"; then
        version="older than 5"
    else
        version="not found"
    fi

    echo "$version"
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_libc.so>"
    exit 1
fi

libc_path="$1"

if [ ! -f "$libc_path" ]; then
    echo "Error: File not found: $libc_path"
    exit 1
fi

jemalloc_version=$(get_jemalloc_version "$libc_path")

case "$jemalloc_version" in
    "5 or later")
        echo "Jemalloc version: likely 5 or later (new)"
        exit 0
        ;;
    "older than 5")
        echo "Jemalloc version: older than 5 (old)"
        exit 0
        ;;
    "not found")
        echo "Jemalloc not detected in this libc.so"
        exit 1
        ;;
    *)
        echo "Error: Unexpected result"
        exit 1
        ;;
esac
