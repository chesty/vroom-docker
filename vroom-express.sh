#!/bin/sh

# https://github.com/docker/docker/issues/6880
cat <> /vroom-express/logpipe 1>&2 &

exec gosu osm node /vroom-express/src/index.js
