#!/bin/bash

SCRIPTFOLDER=$(dirname `realpath $0`)
source ${SCRIPTFOLDER}/.env

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
