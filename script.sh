#!/usr/bin/env bash
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. See
# <https://creativecommons.org/publicdomain/zero/1.0/> for a copy of the CC0
# Public Domain Dedication, which applies to this software.
set -e

psnr_threshold=50

command_fifo=/tmp/mpv-test-fifo-$$-$RANDOM
trap 'rm -f "$command_fifo"' EXIT INT TERM HUP
mkfifo -m 600 "$command_fifo"

mpv --no-config --no-osc --no-hidpi-window-scale --idle --input-file="$command_fifo" &
mpv_pid=$!

printf >>"$command_fifo" 'set pause yes\n'
printf >>"$command_fifo" 'loadfile %s\n' "test-001-input."*
sleep 1
rm -f 'test-001-actual.png'
printf >>"$command_fifo" 'screenshot-to-file test-001-actual.png window\n'
printf >>"$command_fifo" 'quit\n'

wait $mpv_pid
psnr=$(compare 2>&1 >/dev/null -metric PSNR test-001-actual.png test-001-expected.png test-001-diff.png || true)

if [[ $psnr == 'inf' ]] || [[ $psnr == '0' ]] \
     || [[ $(echo "$psnr > $psnr_threshold" | bc) == '1' ]]; then
	printf 'success (PSNR: %s)\n' "$psnr"
	exit 0
else
	printf 'failure (PSNR: %s)\n' "$psnr"
	exit 1
fi
