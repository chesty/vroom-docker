#!/bin/sh

# https://github.com/docker/docker/issues/6880
cat <> /vroom-express/logpipe 1>&2 &

exec node /vroom-express/src/index.js
