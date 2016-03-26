#!/usr/bin/env bash
set -e

psnr_threshold=50

command_fifo=/tmp/mpv-test-fifo-$$-$RANDOM
trap 'rm -f "$command_fifo"' EXIT INT TERM HUP
mkfifo -m 600 "$command_fifo"

mpv --no-config --no-osc --idle --input-file="$command_fifo" &
mpv_pid=$!

printf >>"$command_fifo" 'set pause yes\n'
printf >>"$command_fifo" 'loadfile %s\n' "test-001-input."*
sleep 1
rm -f 'test-001-actual.png'
printf >>"$command_fifo" 'screenshot-to-file test-001-actual.png window\n'
printf >>"$command_fifo" 'quit\n'

wait $mpv_pid
psnr=$(compare 2>&1 >/dev/null -metric PSNR test-001-actual.png test-001-expected.png test-001-diff.png || true)

if [[ $psnr == 'inf' ]] || [[ $(echo "$psnr > $psnr_threshold" | bc) == '1' ]]; then
	printf 'success (PSNR: %s)\n' "$psnr"
	exit 0
else
	printf 'failure (PSNR: %s)\n' "$psnr"
	exit 1
fi
