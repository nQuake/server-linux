#!/bin/sh

installdir=$(cat ~/.nquakesv/install_dir)

. ~/.nquakesv/config

generate_server_config() {
  inputfile=$1
  outputfile=${installdir}/ktx/pwd.cfg

  [ ! -f ${outputfile} ] && {
    echo "rcon_password \"${SV_RCON}\"" > ${inputfile}
    echo "qtv_password \"\"" >> ${inputfile}
    [ "$(readlink -f $inputfile)" != "$(readlink -f $outputfile)" ] && cp -fn ${inputfile} ${outputfile}
  }
}

generate_qtv_config() {
  port=$1
  inputfile=$2
  outputfile=$3

  [ ! -f ${outputfile} ] && {
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

  [ ! -f ${outputfile} ] && {
    echo "cd \$(cat ~/.nquakesv/install_dir)/qtv/ && screen -dmS qtv ./qtv.bin +exec qtv.cfg" > ${outputfile}
    chmod +x ${outputfile}
  }
}

generate_qwfwd_config() {
  port=$1
  inputfile=$2
  outputfile=$3

  [ ! -f ${outputfile} ] && {
    [ "$(readlink -f $inputfile)" != "$(readlink -f $outputfile)" ] && cp -r ${inputfile} ${outputfile}
    echo "set hostname \"${SV_HOSTNAME} QWfwd\"" >> ${outputfile}
    echo "set net_port ${port}" >> ${outputfile}
  }
}

generate_qwfwd_script() {
  outputfile=${installdir}/run/qwfwd.sh

  [ ! -f ${outputfile} ] && {
    echo "cd \$(cat ~/.nquakesv/install_dir)/qwfwd/ && screen -dmS qwfwd ./qwfwd.bin" > ${outputfile}
    chmod +x ${outputfile}
  }
}

generate_port_config() {
  port=$1
  num=$2
  outputfile=$3

  [ ! -f ${outputfile} ] && {
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

  [ ! -f ${outputfile} ] && {
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
  printf "* Starting mvdsv #${num} (port ${port})..."
  [ ${count} -eq 0 ] && {
    generate_port_config ${port} ${num} ${installdir}/ktx/port_${port}.cfg
    generate_port_script ${port} ${num} ${installdir}/run/port_${port}.sh
    ${installdir}/run/port_${port}.sh > /dev/null &
    echo "[OK]"
  } || echo "[ALREADY RUNNING]"
done

[ -f ~/.nquakesv/qtv ] && {
  qtvport=$(cat ~/.nquakesv/qtv)
  generate_qtv_config ${qtvport} ${installdir}/qtv/qtv_template.cfg ${installdir}/qtv/qtv.cfg
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
  generate_qwfwd_config ${qwfwdport} ${installdir}/qwfwd/qwfwd_template.cfg ${installdir}/qwfwd/qwfwd.cfg
  printf "* Starting qwfwd (port ${qwfwdport})..."
  count=$(ps ax | grep -v grep | grep "./qwfwd.bin" | wc -l)
  [ ${count} -eq 0 ] && {
    generate_qwfwd_script
    $(cat ~/.nquakesv/install_dir)/run/qwfwd.sh > /dev/null &
    echo "[OK]"
  } || echo "[ALREADY RUNNING]"
}
