#!/bin/bash

function stop_port {
  port=$1
  pid=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | awk '{print $1}')
  kill -9 ${pid} >/dev/null
}

for f in ~/.nquakesv/ports/*; do
  port=$(basename ${f})
  [ $(ps ax | grep -v grep | grep "start_servers.sh" | wc -l) -gt 0 ] && killall -9 start_servers.sh
  count=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | wc -l)
  printf "* Stopping mvdsv (port ${port})..."
  [ ${count} -gt 0 ] && {
    stop_port ${port}
    echo "[OK]"
  } || echo "[NOT RUNNING]"
done
