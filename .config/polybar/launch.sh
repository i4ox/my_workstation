#!/usr/bin/env bash

killall -q polybar

echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log

polybar main -r >>/tmp/polybar1.log 2>&1 & disown

echo "Bars launched..."
