#!/bin/sh


killall trayer
sleep 2 && trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x2E3440 --height 22 &

function runOnce() {
    app=$1
    count=$(ps aux | grep $app | wc -l)
    if [[ $count -eq 1 ]]; then
      exec "$app" &
    fi
}

runOnce lxsession
runOnce nm-applet 
runOnce volumeicon
