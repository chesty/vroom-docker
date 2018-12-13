#!/bin/sh

# https://github.com/docker/docker/issues/6880
cat <> /vroom-express/logpipe 1>&2 &


if [ $(id -u) -eq 0 ]; then
    exec gosu vroom node /vroom-express/src/index.js
else
    exec node /vroom-express/src/index.js
fi