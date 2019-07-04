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

start_port() {
  port=$1
  num=$2
  generate_port_config ${port} ${num} ${installdir}/ktx/port_${port}.cfg
  generate_port_script ${port} ${num} ${installdir}/run/port_${port}.sh
  ${installdir}/run/port_${port}.sh > /dev/null &
}

# Run only one server if docker file exists
[ -f ~/.nquakesv/docker ] && {
  echo "* Detected Docker configuration"
  runserver=${1:-mvdsv}
  dockerport=${2:-27500}
  ip=$(cat ~/.nquakesv/ip)
  echo "* Listening on IP: $ip"

  mkdir -p ~/.nquakesv/server/

  [ ! -L $installdir/ktx/demos ] && {
    echo "* Creating demos folder"
    [ ! -d ~/.nquakesv/server/demos ] && cp -r $installdir/ktx/demos ~/.nquakesv/server/demos
    rm -rf $installdir/ktx/demos
    ln -s ~/.nquakesv/server/demos $installdir/ktx/demos
  }

  [ ! -L $installdir/logs ] && {
    echo "* Creating logs folder"
    [ ! -d ~/.nquakesv/server/logs ] && cp -r $installdir/logs ~/.nquakesv/server/logs
    rm -rf $installdir/logs
    ln -s ~/.nquakesv/server/logs $installdir/logs
  }

  [ ! -L $installdir/qtv/qtv_template.cfg ] && {
    echo "* Copying qtv.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/qtv.cfg ] && cp $installdir/qtv/qtv_template.cfg ~/.nquakesv/server/qtv.cfg
    rm $installdir/qtv/qtv_template.cfg
    ln -s ~/.nquakesv/server/qtv.cfg $installdir/qtv/qtv_template.cfg
  }

  [ ! -L $installdir/qwfwd/qwfwd_template.cfg ] && {
    echo "* Copying qwfwd.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/qwfwd.cfg ] && cp $installdir/qwfwd/qwfwd_template.cfg ~/.nquakesv/server/qwfwd.cfg
    rm $installdir/qwfwd/qwfwd_template.cfg
    ln -s ~/.nquakesv/server/qwfwd.cfg $installdir/qwfwd/qwfwd_template.cfg
  }

  [ ! -L $installdir/ktx/port_template.cfg ] && {
    echo "* Copying port.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/port.cfg ] && cp $installdir/ktx/port_template.cfg ~/.nquakesv/server/port.cfg
    rm $installdir/ktx/port_template.cfg
    ln -s ~/.nquakesv/server/port.cfg $installdir/ktx/port_template.cfg
  }

  [ ! -L $installdir/ktx/ktx.cfg ] && {
    echo "* Copying ktx.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/ktx.cfg ] && cp $installdir/ktx/ktx.cfg ~/.nquakesv/server/ktx.cfg
    rm $installdir/ktx/ktx.cfg
    ln -s ~/.nquakesv/server/ktx.cfg $installdir/ktx/ktx.cfg
  }

  [ ! -L $installdir/ktx/mvdsv.cfg ] && {
    echo "* Copying mvdsv.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/mvdsv.cfg ] && cp $installdir/ktx/mvdsv.cfg ~/.nquakesv/server/mvdsv.cfg
    rm $installdir/ktx/mvdsv.cfg
    ln -s ~/.nquakesv/server/mvdsv.cfg $installdir/ktx/mvdsv.cfg
  }

  [ ! -L $installdir/ktx/pwd.cfg ] && {
    echo "* Copying passwords.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/passwords.cfg ] && cp $installdir/ktx/pwd.cfg ~/.nquakesv/server/passwords.cfg
    rm $installdir/ktx/pwd.cfg
    ln -s ~/.nquakesv/server/passwords.cfg $installdir/ktx/pwd.cfg
  }

  [ ! -L $installdir/ktx/matchless.cfg ] && {
    echo "* Copying matchless.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/matchless.cfg ] && cp $installdir/ktx/matchless.cfg ~/.nquakesv/server/matchless.cfg
    rm $installdir/ktx/matchless.cfg
    ln -s ~/.nquakesv/server/matchless.cfg $installdir/ktx/matchless.cfg
  }

  [ ! -L $installdir/ktx/vip_ip.cfg ] && {
    echo "* Copying vip_ip.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/vip_ip.cfg ] && cp $installdir/ktx/vip_ip.cfg ~/.nquakesv/server/vip_ip.cfg
    rm $installdir/ktx/vip_ip.cfg
    ln -s ~/.nquakesv/server/vip_ip.cfg $installdir/ktx/vip_ip.cfg
  }

  [ ! -L $installdir/ktx/ban_ip.cfg ] && {
    echo "* Copying ban_ip.cfg to nquakesv configuration folder"
    [ ! -f ~/.nquakesv/server/ban_ip.cfg ] && cp $installdir/ktx/ban_ip.cfg ~/.nquakesv/server/ban_ip.cfg
    rm $installdir/ktx/ban_ip.cfg
    ln -s ~/.nquakesv/server/ban_ip.cfg $installdir/ktx/ban_ip.cfg
  }

  [ "${runserver}" = "mvdsv" ] && {
    echo "* Starting MVDSV"
    generate_server_config ~/.nquakesv/server/passwords.cfg
    generate_port_config $dockerport 1 ${installdir}/ktx/port1.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./mvdsv -port $dockerport -game ktx +exec port1.cfg
  }

  [ "${runserver}" = "qtv" ] && {
    echo "* Starting QTV"
    generate_qtv_config $dockerport ~/.nquakesv/server/qtv.cfg ${installdir}/qtv/qtv.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./qtv/qtv.bin +exec qtv.cfg
  }

  [ "${runserver}" = "qwfwd" ] && {
    echo "* Starting QWFWD"
    generate_qwfwd_config $dockerport ~/.nquakesv/server/qwfwd.cfg ${installdir}/qwfwd/qwfwd.cfg
    cd $(cat ~/.nquakesv/install_dir)
    ./qwfwd/qwfwd.bin
  }
}

[ ! -f ~/.nquakesv/docker ] && {
  generate_server_config ${installdir}/ktx/pwd.cfg

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
}
