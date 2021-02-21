#!/bin/sh

cd /vroom-express
# https://github.com/docker/docker/issues/6880
unbuffer cat /vroom-express/logpipe &
unbuffer cat /vroom-express/access.log &
unbuffer cat /vroom-express/error.log &

if [ $(id -u) -eq 0 ]; then
    exec gosu vroom npm start
else
    exec npm start
fi
