#!/bin/bash

SCRIPTFOLDER=$(dirname `realpath $0`)
source ${SCRIPTFOLDER}/.env

function generate_server_config {
  echo "rcon_password \"${SV_RCON}\"" > ktx/pwd.cfg
  echo "qtv_password \"${SV_QTVPASS}\"" >> ktx/pwd.cfg
}

function generate_qtv_config {
  port=$1
  outputfile=$2
  cp -r ${SCRIPTFOLDER}/qtv/qtv_template.cfg ${outputfile}
  echo "hostname \"${SV_HOSTNAME} Qtv\"" >> ${outputfile}
  echo "admin_password \"${SV_QTVPASS}\"" >> ${outputfile}
  echo "mvdport ${port}" >> ${outputfile}

  ip=$(cat ~/.nquakesv/ip)
  for f in ~/.nquakesv/ports/*; do
    port=$(basename ${f})
    echo "qtv ${ip}:${port}" >> qtv/qtv.cfg
  done
}

function generate_qwfwd_config {
  port=$1
  outputfile=$2
  cp -r ${SCRIPTFOLDER}/qwfwd/qwfwd_template.cfg ${outputfile}
  echo "set hostname \"${SV_HOSTNAME} QWfwd\"" >> ${outputfile}
  echo "set net_port ${port}" >> ${outputfile}
}

function generate_port_config {
  port=$1
  num=$2
  outputfile=$3
  cat ${SCRIPTFOLDER}/ktx/port_template.cfg > ${outputfile}
  echo "set k_motd1 \"${SV_HOSTNAME} #${num}\"" >> ${outputfile}
  echo "hostname \"${SV_HOSTNAME}\"" >> ${outputfile}
  echo "sv_admininfo \"${SV_ADMININFO}\"" >> ${outputfile}
  echo "sv_serverip \"$(cat ~/.nquakesv/ip):${port}\"" >> ${outputfile}
  echo "qtv_streamport \"${port}\"" >> ${outputfile}
}

function generate_port_script {
  port=$1
  num=$2
  outputfile=$3
  echo "while true; do ./mvdsv -port ${port} -game ktx +exec port${num}.cfg; done;" > ${outputfile}
  chmod +x ${outputfile}
}

function start_port {
  port=$1
  num=$2
  generate_port_config ${port} ${num} ${SCRIPTFOLDER}/ktx/port${num}.cfg
  generate_port_script ${port} ${num} ${SCRIPTFOLDER}/run/port${num}.sh
  ${SCRIPTFOLDER}/run/port${num}.sh >/dev/null &
}

generate_server_config

num=0
for f in ~/.nquakesv/ports/*; do
  num=$((${num}+1))
  port=$(basename ${f})
  count=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | wc -l)
  printf "* Starting mvdsv #${num} (port ${port})..."
  [ ${count} -eq 0 ] && {
    start_port ${port} ${num}
    echo "[OK]"
  } || echo "[ALREADY RUNNING]"
done

[ -f ~/.nquakesv/qtv ] && {
  qtvport=$(cat ~/.nquakesv/qtv)
  generate_qtv_config ${qtvport} ${SCRIPTFOLDER}/qtv/qtv.cfg
  printf "* Starting qtv (port ${qtvport})..."
  count=$(ps ax | grep -v grep | grep "qtv.bin +exec qtv.cfg" | wc -l)
  [ ${count} -eq 0 ] && {
    ./run/qtv.sh > /dev/null &
    echo "[OK]"
  } || echo "[ALREADY RUNNING]"
}

[ -f ~/.nquakesv/qwfwd ] && {
  qwfwdport=$(cat ~/.nquakesv/qwfwd)
  generate_qwfwd_config ${qwfwdport} ${SCRIPTFOLDER}/qwfwd/qwfwd.cfg
  printf "* Starting qwfwd (port ${qwfwdport})..."
  count=$(ps ax | grep -v grep | grep "./qwfwd.bin" | wc -l)
  [ ${count} -eq 0 ] && {
    ./run/qwfwd.sh > /dev/null &
    echo "[OK]"
  } || echo "[ALREADY RUNNING]"
}
