#!/bin/bash

coproc bluetoothctl
echo -e 'info 00:A0:50:29:34:D5\nexit' >&${COPROC[1]}
output=$(cat <&${(COPROC[0])}
echo $output
