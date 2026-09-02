#!/usr/bin/env bash
set -euo pipefail

# Error if cpio is not installed
if ! command -v cpio &> /dev/null; then
    echo "cpio not found"
    exit 1
fi

base="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
pushd "$base" &>/dev/null || exit 1

archive="$base/initramfs.cpio"

if [ -f "$archive" ]; then
    rm "$archive"
fi

# Error if the alpine rootfs has not been extracted yet
if [ ! -d "$base/build/rootfs" ]; then
    echo "$base/build/rootfs not found, run scripts/create-image.sh"
    exit 1
fi

# Lay out the directories in $base/build/initramfs that init expects
if [ -d "$base/build/initramfs" ]; then
    rm -rf "$base/build/initramfs"
fi
mkdir -p build/initramfs/{bin,lib,dev,proc,sys,tmp,new-root}

# Copy busybox over and point sh at it, a shell is all we need in here
cp "$base/build/rootfs/bin/busybox" "$base/build/initramfs/bin/"
ln -s busybox "$base/build/initramfs/bin/sh"

# Copy the musl loader and libc that busybox is linked against
cp -a "$base/build/rootfs"/lib/ld-musl-*.so.* "$base/build/rootfs"/lib/libc.musl-*.so.* "$base/build/initramfs/lib/"

# make archive
(cd "$base/build/initramfs" && find . | cpio -o -H newc) > "$archive"
