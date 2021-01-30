#!/bin/sh

cd "$(dirname "$0")"

if [ "$1" = "--release" ] ; then
    exec monkeyc -w -f monkey.jungle -y ../.connect_iq_developer_key.der -o bin/Garmin_Chooser.prg -r -g >_dump.txt 2>&1
else
    exec monkeyc -w -f monkey.jungle -y ../.connect_iq_developer_key.der -o bin/Garmin_Chooser.prg -g >_dump.txt 2>&1
fi
