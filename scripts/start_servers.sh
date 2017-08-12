#!/bin/sh

SCRIPTFOLDER=$(dirname `readlink -f "$0"`)
. ~/.nquakesv/config

generate_server_config() {
  echo "rcon_password \"${SV_RCON}\"" > ${SCRIPTFOLDER}/ktx/pwd.cfg
  echo "qtv_password \"${SV_QTVPASS}\"" >> ${SCRIPTFOLDER}/ktx/pwd.cfg
}

generate_qtv_config() {
  port=$1
  outputfile=$2
  cp -r ${SCRIPTFOLDER}/qtv/qtv_template.cfg ${outputfile}
  echo "hostname \"${SV_HOSTNAME} Qtv\"" >> ${outputfile}
  echo "admin_password \"${SV_QTVPASS}\"" >> ${outputfile}
  echo "mvdport ${port}" >> ${outputfile}

  ip=$(cat ~/.nquakesv/ip)
  for f in ~/.nquakesv/ports/*; do
    port=$(basename ${f})
    echo "qtv ${ip}:${port}" >> ${outputfile}
  done
}

generate_qtv_script() {
  outputfile=${SCRIPTFOLDER}/run/qtv.sh
  echo "screen -dmS qtv \$(cat ~/.nquakesv/install_dir)/qtv/qtv.bin +exec qtv.cfg" > ${outputfile}
  chmod +x ${outputfile}
}

generate_qwfwd_config() {
  port=$1
  outputfile=$2
  cp -r ${SCRIPTFOLDER}/qwfwd/qwfwd_template.cfg ${outputfile}
  echo "set hostname \"${SV_HOSTNAME} QWfwd\"" >> ${outputfile}
  echo "set net_port ${port}" >> ${outputfile}
}

generate_qwfwd_script() {
  outputfile=${SCRIPTFOLDER}/run/qwfwd.sh
  echo "screen -dmS qwfwd \$(cat ~/.nquakesv/install_dir)/qwfwd/qwfwd.bin" > ${outputfile}
  chmod +x ${outputfile}
}

generate_port_config() {
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

generate_port_script() {
  port=$1
  num=$2
  outputfile=$3
  echo "screen -dmS qw_$port \$(cat ~/.nquakesv/install_dir)/mvdsv -port ${port} -game ktx +exec port${num}.cfg" > ${outputfile}
  chmod +x ${outputfile}
}

start_port() {
  port=$1
  num=$2
  generate_port_config ${port} ${num} ${SCRIPTFOLDER}/ktx/port${num}.cfg
  generate_port_script ${port} ${num} ${SCRIPTFOLDER}/run/port${num}.sh
  ${SCRIPTFOLDER}/run/port${num}.sh > /dev/null &
}

# Run only one server if docker file exists
[ -f ~/.nquakesv/docker ] && {
  echo "* Detected Docker configuration"
  runserver=$(cat ~/.nquakesv/docker)
  runport=$(cat ~/.nquakesv/docker-port)

  [ "${runserver}" = "mvdsv" ] && {
    echo "* Starting MVDSV"
    generate_server_config
    generate_port_config ${runport:-27500} 1 ${SCRIPTFOLDER}/ktx/port1.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./mvdsv -port ${runport:-27500} -game ktx +exec port1.cfg
  }

  [ "${runserver}" = "qtv" ] && {
    echo "* Starting QTV"
    generate_qtv_config ${runport:-27500} ${SCRIPTFOLDER}/qtv/qtv.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./qtv/qtv.bin +exec qtv.cfg
  }

  [ "${runserver}" = "qwfwd" ] && {
    echo "* Starting QWFWD"
    generate_qwfwd_config ${runport:-27500} ${SCRIPTFOLDER}/qwfwd/qwfwd.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./qwfwd/qwfwd.bin
  }
}

[ ! -f ~/.nquakesv/docker ] && {
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
      generate_qtv_script
      $(cat ~/.nquakesv/install_dir)/run/qtv.sh > /dev/null &
      echo "[OK]"
    } || echo "[ALREADY RUNNING]"
  }

  [ -f ~/.nquakesv/qwfwd ] && {
    qwfwdport=$(cat ~/.nquakesv/qwfwd)
    generate_qwfwd_config ${qwfwdport} ${SCRIPTFOLDER}/qwfwd/qwfwd.cfg
    printf "* Starting qwfwd (port ${qwfwdport})..."
    count=$(ps ax | grep -v grep | grep "./qwfwd.bin" | wc -l)
    [ ${count} -eq 0 ] && {
      generate_qwfwd_script
      $(cat ~/.nquakesv/install_dir)/run/qwfwd.sh > /dev/null &
      echo "[OK]"
    } || echo "[ALREADY RUNNING]"
  }
}
