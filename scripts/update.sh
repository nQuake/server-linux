#!/bin/sh

installdir=$(cat ~/.nquakesv/install_dir)

nqecho() {
  nqnecho "$* \n"
}

nqnecho() {
  [ -z "${quiet}" ] && printf "$*"
}

nqeecho() {
  [ -z "${extraquiet}" ] && printf "$*"
}

nqiecho() {
  [ -z "${noninteractive}" ] && nqecho $*
}

nqwget() {
  [ -n "${quiet}" ] && {
    wget -q --progress=dot:giga $* >/dev/null 2>&1
  } || {
    wget --progress=dot:giga $*
  }
}

githubdl() {
  localpath=$1
  remotepath=$2
  nqwget -q -O ${localpath} https://raw.githubusercontent.com/nQuake/server-linux/master/${remotepath}
  chmod +x ${localpath}
}

nqnecho "* Downloading shell scripts..."
(githubdl ${installdir}/start_servers.sh scripts/start_servers.sh && \
githubdl ${installdir}/stop_servers.sh scripts/stop_servers.sh && \
githubdl ${installdir}/update.sh scripts/update.sh && \
githubdl ${installdir}/update_binaries.sh scripts/update_binaries.sh && \
githubdl ${installdir}/update_configs.sh scripts/update_configs.sh && \
githubdl ${installdir}/update_maps.sh scripts/update_maps.sh && echo done) || nqecho fail
nqecho

exit 0
