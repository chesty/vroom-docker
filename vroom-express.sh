#!/bin/sh

cd /vroom-express
# https://github.com/docker/docker/issues/6880
cat <> /vroom-express/logpipe 1>&2 &


if [ $(id -u) -eq 0 ]; then
    exec gosu vroom npm start
else
    exec npm start
fi
