#!/bin/sh

# Obsolete file, replaced by update_scripts.sh - Only here for backwards compatibility

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
    wget -q $* >/dev/null 2>&1
  } || {
    wget $*
  }
}

githubdl() {
  localpath=$1
  remotepath=$2
  nqwget -q -O ${localpath} https://raw.githubusercontent.com/nQuake/server-linux/master/${remotepath}
  chmod +x ${localpath}
}

githubd2() {
  localpath=$1
  remotepath=$2
  nqwget -q -O ${localpath} https://raw.githubusercontent.com/ciscon/random/blob/master/${remotepath}
  chmod +x ${localpath}
}

nqnecho "* Downloading shell scripts..."
(githubdl ${directory}/start_servers.sh scripts/start_servers.sh && \
githubdl ${directory}/stop_servers.sh scripts/stop_servers.sh && \
githubdl ${directory}/update_scripts.sh scripts/update.sh && \
githubdl ${directory}/update_binaries.sh scripts/update_binaries.sh && \
githubdl ${directory}/update_configs.sh scripts/update_configs.sh && \
githubdl ${directory}/update_maps.sh scripts/update_maps.sh && \
githubd2 ${directory}/nquakesv-build-mvdsv.sh quake-scripts/build/nquakesv-build-mvdsv.sh && \
githubd2 ${directory}/nquakesv-build-ktx.sh quake-scripts/build/nquakesv-build-ktx.sh && echo done) || nqecho fail
nqecho

nqecho "IMPORTANT: update.sh has been replaced by update_scripts.sh"
nqecho "You can delete update.sh"
nqecho

exit 0
