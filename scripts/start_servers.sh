#!/bin/sh

REGENERATE=""
GENERATE_ONLY=""

for i in "$@"; do
  case ${i} in
    --regenerate)
      REGENERATE=1
      shift
      ;;
    --generate-only)
      GENERATE_ONLY=1
      shift
      ;;
  esac
done

installdir=$(cat ~/.nquakesv/install_dir)

. ~/.nquakesv/config

generate_server_config() {
  inputfile=$1
  outputfile=${installdir}/ktx/pwd.cfg

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    echo "rcon_password \"${SV_RCON}\"" > ${inputfile}
    echo "qtv_password \"\"" >> ${inputfile}
    [ "$(readlink -f $inputfile)" != "$(readlink -f $outputfile)" ] && cp -fn ${inputfile} ${outputfile}
  }
}

generate_qtv_config() {
  port=$1
  inputfile=$2
  outputfile=$3

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    [ "$(readlink -f $inputfile)" != "$(readlink -f $outputfile)" ] && cp -r ${inputfile} ${outputfile}
    echo "hostname \"${SV_HOSTNAME} Qtv\"" >> ${outputfile}
    echo "admin_password \"${SV_QTVPASS}\"" >> ${outputfile}
    echo "mvdport ${port}" >> ${outputfile}

    ip=$(cat ~/.nquakesv/ip)
    echo "address ${ip}:${port}" >> ${outputfile}

    for f in ~/.nquakesv/ports/*; do
      port=$(basename ${f})
      echo "qtv ${ip}:${port}" >> ${outputfile}
    done
  }
}

generate_qtv_script() {
  outputfile=${installdir}/run/qtv.sh

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    echo "cd \$(cat ~/.nquakesv/install_dir)/qtv/ && screen -dmS qtv ./qtv.bin +exec qtv.cfg" > ${outputfile}
    chmod +x ${outputfile}
  }
}

generate_qwfwd_config() {
  port=$1
  inputfile=$2
  outputfile=$3

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    [ "$(readlink -f $inputfile)" != "$(readlink -f $outputfile)" ] && cp -r ${inputfile} ${outputfile}
    echo "set hostname \"${SV_HOSTNAME} QWfwd\"" >> ${outputfile}
    echo "set net_port ${port}" >> ${outputfile}
  }
}

generate_qwfwd_script() {
  outputfile=${installdir}/run/qwfwd.sh

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    echo "cd \$(cat ~/.nquakesv/install_dir)/qwfwd/ && screen -dmS qwfwd ./qwfwd.bin" > ${outputfile}
    chmod +x ${outputfile}
  }
}

generate_port_config() {
  port=$1
  num=$2
  outputfile=$3

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    cat ${installdir}/ktx/port_template.cfg > ${outputfile}
    echo "set k_motd1 \"${SV_HOSTNAME} #${num}\"" >> ${outputfile}
    echo "hostname \"${SV_HOSTNAME}:${port}\"" >> ${outputfile}
    echo "sv_admininfo \"${SV_ADMININFO}\"" >> ${outputfile}
    echo "sv_serverip \"$(cat ~/.nquakesv/ip):${port}\"" >> ${outputfile}
    echo "qtv_streamport \"${port}\"" >> ${outputfile}
  }
}

generate_port_script() {
  port=$1
  num=$2
  outputfile=$3

  ( [ ! -f ${outputfile} ] || [ ! -z ${REGENERATE} ] ) && {
    echo "cd \$(cat ~/.nquakesv/install_dir)/ && screen -dmS qw_$port ./mvdsv -port ${port} -game ktx +exec port_${port}.cfg" > ${outputfile}
    chmod +x ${outputfile}
  }
}

generate_server_config ${installdir}/ktx/pwd.cfg

num=0
for f in ~/.nquakesv/ports/*; do
  num=$((${num}+1))
  port=$(basename ${f})
  count=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | wc -l)
  if [ ${count} -eq 0 ]; then
    generate_port_config ${port} ${num} ${installdir}/ktx/port_${port}.cfg
    generate_port_script ${port} ${num} ${installdir}/run/port_${port}.sh
  fi
  if [ -z "${GENERATE_ONLY}" ]; then
    printf "* Starting mvdsv #${num} (port ${port})..."
    if [ ${count} -eq 0 ]; then
      ${installdir}/run/port_${port}.sh > /dev/null &
      echo "[OK]"
    else
      echo "[ALREADY RUNNING]"
    fi
  fi
done

if [ -f ~/.nquakesv/qtv ]; then
  qtvport=$(cat ~/.nquakesv/qtv)
  count=$(ps ax | grep -v grep | grep "qtv.bin +exec qtv.cfg" | wc -l)
  if [ ${count} -eq 0 ]; then
    generate_qtv_config ${qtvport} ${installdir}/qtv/qtv_template.cfg ${installdir}/qtv/qtv.cfg
    generate_qtv_script
  fi
  if [ -z "${GENERATE_ONLY}" ]; then
    printf "* Starting qtv (port ${qtvport})..."
    if [ ${count} -eq 0 ]; then
      $(cat ~/.nquakesv/install_dir)/run/qtv.sh > /dev/null &
      echo "[OK]"
    else
      echo "[ALREADY RUNNING]"
    fi
  fi
fi

if [ -f ~/.nquakesv/qwfwd ]; then
  qwfwdport=$(cat ~/.nquakesv/qwfwd)
  count=$(ps ax | grep -v grep | grep "./qwfwd.bin" | wc -l)
  if [ ${count} -eq 0 ]; then
    generate_qwfwd_config ${qwfwdport} ${installdir}/qwfwd/qwfwd_template.cfg ${installdir}/qwfwd/qwfwd.cfg
    generate_qwfwd_script
  fi
  if [ -z "${GENERATE_ONLY}" ]; then
    printf "* Starting qwfwd (port ${qwfwdport})..."
    if [ ${count} -eq 0 ]; then
      $(cat ~/.nquakesv/install_dir)/run/qwfwd.sh > /dev/null &
      echo "[OK]"
    else
      echo "[ALREADY RUNNING]"
    fi
  fi
fi
