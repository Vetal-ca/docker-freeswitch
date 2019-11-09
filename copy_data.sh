#!/usr/bin/env sh

echo "Copying sound files ..."
cp -R /usr/share/freeswitch/sounds/* /sounds
echo "Copy is done"


# Wait after copy, so container is not restarted
echo "Waiting for TERM signal . . ."
tail -fn0 $0 & PID=$!
trap "kill $PID" INT TERM

wait


echo "TERM signal is recieved, exit"