#!/bin/sh

if [ $(ps ax | grep -v grep | grep "start_servers.sh" | wc -l) -gt 0 ]; then
  killall -9 start_servers.sh
fi

for f in ~/.nquakesv/ports/*; do
  port=$(basename ${f})
  count=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | wc -l)
  printf "* Stopping mvdsv (port ${port})..."
  if [ ${count} -gt 0 ]; then
    pid=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | grep "SCREEN" | awk '{print $1}')
    kill -9 ${pid} >/dev/null
    echo "[OK]"
  else
    echo "[NOT RUNNING]"
  fi
done

if [ -f ~/.nquakesv/qtv ]; then
  qtvport=$(cat ~/.nquakesv/qtv)
  printf "* Stopping qtv (port ${qtvport})..."
  count=$(ps ax | grep -v grep | grep "qtv.bin +exec qtv.cfg" | wc -l)
  if [ ${count} -gt 0 ]; then
    pid=$(ps ax | grep -v grep | grep "qtv.bin +exec qtv.cfg" | grep "SCREEN" | awk '{print $1}')
    kill -9 ${pid} >/dev/null
    echo "[OK]"
  else
    echo "[NOT RUNNING]"
  fi
fi

if [ -f ~/.nquakesv/qwfwd ]; then
  qwfwdport=$(cat ~/.nquakesv/qwfwd)
  printf "* Stopping qwfwd (port ${qwfwdport})..."
  count=$(ps ax | grep -v grep | grep "qwfwd.bin" | wc -l)
  if [ ${count} -gt 0 ]; then
    pid=$(ps ax | grep -v grep | grep "qwfwd.bin" | grep "SCREEN" | awk '{print $1}')
    kill -9 ${pid} >/dev/null
    echo "[OK]"
  else
    echo "[NOT RUNNING]"
  fi
fi

screen -wipe
