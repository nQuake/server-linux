#!/bin/sh

# Usage info
show_help() {
cat << EOF
usage: install_nquakesv.sh [-h|--help] [-n|--non-interactive]
                           [-q|--quiet] [-qq|--extra-quiet]
                           [-o|--hostname=<hostname>]
                           [-p|--number-of-ports=<count>] [-nt|--no-qtv] [-nf|--no-qwfwd]
                           [-l|--listen-address=<address>]
                           [-a|--admin=<name>] [-e|--admin-email=<email>]
                           [-r|--rcon-password=<password>] [-y|--qtv-password=<password>]
                           [-s[=<path>]|--search-pak[=<path>]]
                           [-c|--no-cron] [TARGETDIR]
                           [-u|--no-update-config]
                           [-b|--no-build]

    -h, --help              display this help and exit.
    -n, --non-interactive   non-interactive mode (use defaults or command line
                            parameters, and do not prompt for anything).
    -q, --quiet             do not output informative messages during setup. this
                            will not silence messages that require interaction.
    -qq, --extra-quiet      do not output errors during setup.
    -o, --hostname          hostname of the server.
    -p, --number-of-ports   number of ports to run.
    -t, --qtv               install qtv (default, kept for backwards compatibility).
    -f, --qwfwd             install qwfwd proxy (default, kept for backwards compatibility).
    -nt, --no-qtv           do not install qtv.
    -nf, --no-qwfwd         do not install qwfwd proxy.
    -l, --listen-address    fully qualified domain name (fqdn) or IP address.
    -a, --admin             administrator name.
    -e, --admin-email       administrator e-mail.
    -r, --rcon-password     rcon password.
    -y, --qtv-password      qtv password.
    -s, --search-pak        search for pak1.pak during setup, specify a directory
                            to start searching there instead of in home folder.
    -c, --no-cron           don't add cron job.
    -u, --no-update-config  don't update configuration files in ~/.nquakesv.
    -b, --no-build          don't run nquakesv-build-mvdsv.sh and nquakesv-build-ktx.sh scripts to build mvdsv and ktx.
EOF
}

created=0
nondefaultrcon=

# Parse command line parameters
noninteractive=""
quiet=""
extraquiet=""
nqhostname=""
nqnumports=""
nqinstallqtv=""
nqinstallqwfwd=""
nqaddr=""
nqadmin=""
nqemail=""
nqrcon=""
nqqtvpassword=""
nqsearchpak=""
searchdir=""
nqaddcron=""
nqupdateconfig=""
nqbuild=""
nqinstalldir=""

for i in "$@"; do
  case ${i} in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--non-interactive)
      noninteractive=1
      shift
      ;;
    -q|--quiet)
      quiet=1
      shift
      ;;
    -qq|--extra-quiet)
      extraquiet=1
      shift
      ;;
    -o=*|--hostname=*)
      nqhostname="${i#*=}"
      shift
      ;;
    -p=*|--number-of-ports=*)
      nqnumports="${i#*=}"
      shift
      ;;
    -t|--qtv)
      nqinstallqtv="y"
      shift
      ;;
    -f|--qwfwd)
      nqinstallqwfwd="y"
      shift
      ;;
    -nt|--no-qtv)
      nqinstallqtv="n"
      shift
      ;;
    -nf|--no-qwfwd)
      nqinstallqwfwd="n"
      shift
      ;;
    -l=*|--listen-address=*)
      nqaddr="${i#*=}"
      shift
      ;;
    -a=*|--admin=*)
      nqadmin="${i#*=}"
      shift
      ;;
    -e=*|--admin-email=*)
      nqemail="${i#*=}"
      shift
      ;;
    -r=*|--rcon-password=*)
      nqrcon="${i#*=}"
      nondefaultrcon=1
      shift
      ;;
    -y=*|--qtv-password=*)
      nqqtvpassword="${i#*=}"
      shift
      ;;
    -s=*|--search-pak=*)
      nqsearchpak="y"
      searchdir="${i#*=}"
      shift
      ;;
    -s|--search-pak)
      nqsearchpak="y"
      shift
      ;;
    -c|--no-cron)
      nqaddcron="n"
      shift
      ;;
    -u|--no-update-config)
      nqupdateconfig="n"
      shift
      ;;
    -b|--no-build)
      nqbuild="n"
      shift
      ;;
    *)
      nqinstalldir="${i#*=}"
      ;;
  esac
done

# Defaults (use cmdline parameters)
defaultdir=${nqinstalldir:-\~/nquakesv}
defaulthostname=${nqhostname:-"KTX Allround"}
defaultports=${nqnumports:-4}
defaultqtv=${nqinstallqtv:-y}
defaultqwfwd=${nqinstallqwfwd:-y}
defaultadmin=${nqadmin:-${USER}}
defaultemail=${nqemail:-${defaultadmin}@example.com}
defaultrcon=${nqrcon:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12;echo)}
defaultqtvpass=${nqqtvpassword:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12;echo)}
defaultsearchoption=${nqsearchpak:-n}
defaultsearchdir=${searchdir:-\~/}
defaultaddcron=${nqaddcron:-y}
defaultupdateconfig=${nqupdateconfig:-y}
defaultbuild=${nqbuild:-y}

error() {
  printf "ERROR: %s\n" "$*"
  [ "${created}" -eq 1 ] && {
    cd
    nqeecho "The directory ${directory} is about to be removed, press ENTER to confirm or CTRL+C to exit."
    read dummy
    rm -rf ${directory}
  }
  exit 1
}

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

# Check if unzip, curl, wget and screen is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the nQuakesv installation again."
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the nQuakesv installation again."
which wget >/dev/null || error "The package 'wget' is not installed. Please install it and run the nQuakesv installation again."
which screen >/dev/null || error "The package 'screen' is not installed. Please install it and run the nQuakesv installation again.";

nqecho
nqecho "Welcome to the nQuakesv installation"
nqecho "===================================="
nqiecho
nqiecho "Press ENTER to use [default] option."
nqiecho

# Interactive stuff
[ -z "${noninteractive}" ] && {
  # Install dir
  printf "Where do you want to install nQuakesv? [${defaultdir}]: "
  read directory
  eval directory=${directory}

  # Hostname
  printf "Enter a descriptive hostname [${defaulthostname}]: "
  read hostname

  # FQDN/IP
  [ -z "${nqaddr}" ] && {
          printf "Enter your server's fully qualified domain name (or IP address). [use external IP]: "
  } || {
          printf "Enter your server's fully qualified domain name (or IP address). [${nqaddr}]: "
  }
  read hostdns

  # Ports
  printf "How many ports of KTX do you wish to run (max 64)? [${defaultports}]: "
  read ports

  # Rcon
  printf "What should the rcon password be? [${defaultrcon}]: "
  read rcon

  # QTV
  printf "Do you wish to run a qtv? (y/n) [${defaultqtv}]: "
  read qtv
  [ "${qtv}" = "y" ] && {
    printf "What should the qtv admin password be? [${defaultqtvpass}]: "
    read qtvpass
  }

  # QWFWD
  printf "Do you wish to run a qwfwd proxy? (y/n) [${defaultqwfwd}]: "
  read qwfwd

  # Admin name
  printf "Who is the admin of this server? [${defaultadmin}]: "
  read admin

  # Admin email
  printf "What is the admin's e-mail? [${defaultemail}]: "
  read email

  # Search for Pak1
  printf "Do you want setup to search for pak1.pak? (y/n) [${defaultsearchoption}]: "
  read search
  [ "${search}" = "y" ] || ([ "${defaultsearchoption}" = "y" ] && [ -z "${search}" ]) && {
    printf "Enter path to recursively search for pak1.pak [${defaultsearchdir}]: "
    read path
  }
}

review=""
nqecho
nqiecho "Please review the following settings:"
nqecho "========================================="
# Set defaults if nothing was entered (non-interactive mode or just use defaults)
[ -z "${directory}" ] && eval directory=${defaultdir}
[ -z "${hostname}" ] && hostname=${defaulthostname}
[ -z "${hostdns}" ] && hostdns=${nqaddr}
[ -z "${ports}" ] && ports=${defaultports}
[ -z "${rcon}" ] && rcon=${defaultrcon}
[ -z "${qtv}" ] && qtv=${defaultqtv}
[ -z "${qtvpass}" ] && qtvpass=${defaultqtvpass}
[ -z "${qwfwd}" ] && qwfwd=${defaultqwfwd}
[ -z "${admin}" ] && admin=${defaultadmin}
[ -z "${email}" ] && email=${defaultemail}
[ -z "${search}" ] && search=${defaultsearchoption}
[ -z "${path}" ] && path=${defaultsearchdir}

nqecho "Install directory:   ${directory}"
nqecho "Hostname:            ${hostname}"
nqnecho "Listen address:      "
[ -z "${hostdns}" ] && nqecho "<resolve address>" || nqecho "${hostdns}"
nqecho "Number of ports:     ${ports}"
nqecho "RCON password:       ${rcon}"
nqnecho "Install QTV:         "
[ "${qtv}" = "y" ] && nqecho "yes (password: ${qtvpass})" || nqecho "no"
nqnecho "Install QWFWD:       "
[ "${qwfwd}" = "y" ] && nqecho "yes" || nqecho "no"
nqecho "Admin:               ${admin} <${email}>"
nqnecho "Search for pak1:     "
[ "${search}" = "y" ] && nqecho "${path}" || nqecho "<do not search>"
nqecho "========================================="

[ -z "${noninteractive}" ] && {
  nqecho
  nqecho "Press any key to continue..."
  read review
}

# Adjust invalid ports
[ "${ports}" -gt 64 ] && ports=64
[ "${ports}" -lt 1 ] && ports=1

nqecho "Installation proceeding..."

# Create the nQuakesv folder
[ -d "${directory}" ] && {
  [ -w "${directory}" ] && {
    created=0
  } || error "You do not have write access to '${directory}'. Exiting."
} || {
  [ -e "${directory}" ] && {
    error "'${directory}' already exists but is a file, not a directory. Exiting."
  } || {
    mkdir -p ${directory} 2>/dev/null || error "Failed to create install directory: '${directory}'"
    created=1
  }
}

[ -w "${directory}" ] && {
  cd ${directory}
  directory=$(pwd)
} || error "You do not have write access to ${directory}. Exiting."

# Search for pak1.pak
pak=""
[ "${search}" = "y" ] && {
  eval path=${path}
  pak=$(echo $(find ${path} -type f -iname "pak1.pak" -size 33M -exec echo "{}" \; 2> /dev/null) | cut -d " " -f1)
  [ -n "${pak}" ] && {
    nqecho
    nqecho "* Found pak1.pak at location: ${pak}"
  } || {
    nqecho
    nqecho "* Could not find pak1.pak"
  }
}
nqecho

# Download nquake.ini
nqwget -q -O nquake.ini https://raw.githubusercontent.com/nQuake/client-win32/master/etc/nquake.ini || error "Failed to download nquake.ini"
[ ! -s "nquake.ini" ] && error "Downloaded nquake.ini but file is empty?! Exiting."

# List all the available mirrors
[ -z "${noninteractive}" ] && {
  nqecho "From what mirror would you like to download nQuakesv?"
  grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
  nqnecho "Enter mirror number [random]: "
  read mirror
  mirror=$(grep "^${mirror}=\(http\|https\|ftp\)://[^ ]*$" nquake.ini | cut -d "=" -f2)
  nqecho
}
[ -z "${mirror}" ] && {
  nqnecho "Using mirror: "
  range=$(expr $(grep "[0-9]\{1,2\}=\".*" nquake.ini | wc -l) + 1)
  while [ -z "${mirror}" ]; do
    number=$((((RANDOM<<15)|RANDOM) % $range + 1))
    mirror=$(grep "^${number}=\(http\|https\|ftp\)://[^ ]*$" nquake.ini | cut -d "=" -f2)
    mirrorname=$(grep "^${number}=\".*" nquake.ini | cut -d "\"" -f2)
  done
  nqecho "${mirrorname}"
}
mkdir -p id1
mkdir -p demos_archive
nqecho

# Download all the packages
nqecho "=== Downloading ==="
nqwget -O qsw106.zip ${mirror}/qsw106.zip || error "Failed to download ${mirror}/qsw106.zip"
[ ! -s "qsw106.zip" ] && error "Downloaded qwsv106.zip but file is empty?!"
nqwget -O sv-gpl.zip ${mirror}/sv-gpl.zip || error "Failed to download ${mirror}/sv-gpl.zip"
[ ! -s "sv-gpl.zip" ] && error "Downloaded sv-gpl.zip but file is empty?!"
nqwget -O sv-non-gpl.zip ${mirror}/sv-non-gpl.zip || error "Failed to download ${mirror}/sv-non-gpl.zip"
[ ! -s "sv-non-gpl.zip" ] && error "Downloaded sv-non-gpl.zip but file is empty?!"
nqwget -O sv-bin-x64.zip ${mirror}/sv-bin-x64.zip || error "Failed to download ${mirror}/sv-bin-x64.zip"
[ ! -s "sv-bin-x64.zip" ] && error "Downloaded sv-bin-x64.zip but file is empty?!"
nqwget -O sv-configs.zip ${mirror}/sv-configs.zip || error "Failed to download ${mirror}/sv-configs.zip"
[ ! -s "sv-configs.zip" ] && error "Downloaded sv-configs.zip but file is empty?!"
nqwget -O sv-maps.zip ${mirror}/sv-maps.zip || error "Failed to download ${mirror}/sv-maps.zip"
[ ! -s "sv-maps.zip" ] && error "Downloaded sv-maps.zip but file is empty?!"

# Get external IP address
nqnecho "Resolving external IP address... "
remote_ip=$(curl -f -s https://api.ipify.org/?format=txt)
[ -z "${remote_ip}" ] && error "Failed retrieving external IP address"
[ -z "${hostdns}" ] && hostdns=${remote_ip}
nqecho "Resolved: ${remote_ip}"
nqecho

# Extract all the packages
nqecho "=== Installing ==="
nqnecho "* Extracting Quake Shareware..."
(unzip -qqo qsw106.zip ID1/PAK0.PAK 2>/dev/null && nqecho done) || nqecho fail
nqnecho "* Extracting nQuakesv setup files (1 of 2)..."
(unzip -qqo sv-gpl.zip 2>/dev/null && nqecho done) || nqecho fail
nqnecho "* Extracting nQuakesv setup files (2 of 2)..."
(unzip -qqo sv-non-gpl.zip 2>/dev/null && nqecho done) || nqecho fail
nqnecho "* Extracting nQuakesv binaries..."
(unzip -qqo sv-bin-x64.zip 2>/dev/null && nqecho done) || nqecho fail
nqnecho "* Extracting nQuakesv configuration files..."
(unzip -qqo sv-configs.zip 2>/dev/null && nqecho done) || nqecho fail
nqnecho "* Extracting nQuakesv maps..."
(unzip -qqo sv-maps.zip 2>/dev/null && nqecho done) || nqecho fail
[ -n "$pak" ] && {
  nqecho "* Copying pak1.pak..."
  (cp ${pak} ${directory}/id1/pak1.pak 2>/dev/null && nqecho done) || nqecho fail
}
nqnecho "* Downloading shell scripts..."
(githubdl ${directory}/start_servers.sh scripts/start_servers.sh && \
githubdl ${directory}/stop_servers.sh scripts/stop_servers.sh && \
githubdl ${directory}/update.sh scripts/update.sh && \
githubdl ${directory}/update_binaries.sh scripts/update_binaries.sh && \
githubdl ${directory}/update_configs.sh scripts/update_configs.sh && \
githubdl ${directory}/update_maps.sh scripts/update_maps.sh && \
githubd2 ${directory}/nquakesv-build-mvdsv.sh quake-scripts/build/nquakesv-build-mvdsv.sh && \
githubd2 ${directory}/nquakesv-build-ktx.sh quake-scripts/build/nquakesv-build-ktx.sh && echo done) || nqecho fail
nqecho

# Rename files
nqecho "=== Cleaning up ==="
nqnecho "* Renaming files..."
(mv ${directory}/ID1/PAK0.PAK ${directory}/id1/pak0.pak 2>/dev/null && rm -rf ${directory}/ID1 && nqecho done) || nqecho fail

# Remove distribution files
nqnecho "* Removing distribution files..."
(rm -rf ${directory}/qsw106.zip ${directory}/sv-gpl.zip ${directory}/sv-non-gpl.zip ${directory}/sv-bin-x64.zip ${directory}/sv-configs.zip ${directory}/sv-maps.zip ${directory}/nquake.ini && nqecho done) || nqecho fail

# Convert DOS files to UNIX
nqnecho "* Converting DOS files to UNIX..."
for file in $(find ${directory} -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README"); do
  [ -f "${file}" ] && sed -i 's/\r$//' ${file}
done
nqecho "done"

# Set the correct permissions
nqnecho "* Setting permissions..."
find ${directory} -type f -exec chmod -f 644 "{}" \;
find ${directory} -type d -exec chmod -f 755 "{}" \;
chmod -f +x ${directory}/mvdsv 2>/dev/null
chmod -f +x ${directory}/ktx/mvdfinish.qws 2>/dev/null
chmod -f +x ${directory}/qtv/qtv.bin 2>/dev/null
chmod -f +x ${directory}/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x ${directory}/*.sh 2>/dev/null
chmod -f +x ${directory}/run/*.sh 2>/dev/null
chmod -f +x ${directory}/addons/*.sh 2>/dev/null
nqecho "done"

# Update configuration files
[ -d "$HOME/.nquakesv" ] && {
  [ -z "${noninteractive}" ] && {
    nqecho
    nqnecho "Update configuration files (overwrites ~/.nquakesv/* of previous installation) (y/n) [${defaultupdateconfig}]: "
    read updateconfig
  }
}

# Set default if nothing was entered
[ -z "${updateconfig}" ] && updateconfig=${defaultupdateconfig}

[ "${updateconfig}" = "y" ] && {
  nqnecho "* Updating configuration files..."
  mkdir -p ~/.nquakesv
  echo ${directory} > ~/.nquakesv/install_dir
  echo ${hostdns} > ~/.nquakesv/ip
  echo "${admin} <${email}>" > ~/.nquakesv/admin
  # Generate config file
  echo "SV_HOSTNAME=\"${hostname}\"" > ~/.nquakesv/config
  echo "SV_ADMININFO=\"${admin} <${email}>\"" >> ~/.nquakesv/config
  echo "SV_RCON=\"${rcon}\"" >> ~/.nquakesv/config
  echo "SV_QTVPASS=\"${qtvpass}\"" >> ~/.nquakesv/config
  # qtv
  [ "${qtv}" = "y" ] && {
    echo 28000 > ~/.nquakesv/qtv
    ln -s ${directory}/ktx/demos ${directory}/qtv/demos
    ln -s ${directory}/qw/maps ${directory}/qtv/maps
  }
  # qwfwd
  [ "${qwfwd}" = "y" ] && {
    echo 30000 > ~/.nquakesv/qwfwd
  }
  nqecho "done"

  # Create port files
  nqnecho "* Adjusting amount of ports..."
  mkdir -p ~/.nquakesv/ports
  i=1
  while [ ${i} -le ${ports} ]; do
    [ ${i} -gt 9 ] && port=285${i} || port=2850${i}
    touch ~/.nquakesv/ports/${port}
    i=$((i+1))
  done
  nqecho "done"
}
[ "${updateconfig}" = "y" ] || {
  nqnecho "* Skipping update of configuration files..."
}

# Create cron entries
[ -d "/etc/cron.d" ] && {
  [ -z "${noninteractive}" ] && {
    nqecho
    nqnecho "Add nQuake server to crontab (ensures servers are always on) (y/n) [${defaultaddcron}]: "
    read addcron
  }

  # Set default if nothing was entered
  [ -z "${addcron}" ] && addcron=${defaultaddcron}

  [ "${addcron}" = "y" ] && {
    echo "*/10 * * * * $USER cd \$(cat ~/.nquakesv/install_dir) && ./start_servers.sh >/dev/null 2>&1" | sudo tee /etc/cron.d/nquakesv >/dev/null
    echo "@reboot $USER cd \$(cat ~/.nquakesv/install_dir) && ./start_servers.sh >/dev/null 2>&1" | sudo tee -a /etc/cron.d/nquakesv > /dev/null
    echo "# Uncomment the following line if you would like to move demos older than 90 days to the demos_archive folder (more than 4096 demos in mvdsv causes issues)" | sudo tee -a /etc/cron.d/nquakesv > /dev/null
    echo "#0 13 * * 1 $USER rsync -a \$(cat ~/.nquakesv/install_dir)/ktx/demos/*.mvd \$(cat ~/.nquakesv/install_dir)/demos_archive/. >/dev/null && find \$(cat ~/.nquakesv/install_dir)/ktx/demos -mtime +90 -print0|xargs -r -0 rm -f >/dev/null" | sudo tee -a /etc/cron.d/nquakesv > /dev/null
  }
}

# Build mvdsv and ktx
[ -z "${noninteractive}" ] && {
  nqecho
  nqnecho "Build mvdsv and ktx (ensures server is updated) (y/n) [${defaultbuild}]: "
  read build
}

# Set default if nothing was entered
[ -z "${build}" ] && build=${defaultbuild}

[ "${build}" = "y" ] && {
nqecho "Running ./nquakesv-build-mvdsv.sh ..."
nqecho
./nquakesv-build-mvdsv.sh
nqecho "Running ./nquakesv-build-ktx.sh ..."
nqecho
./nquakesv-build-ktx.sh
nqecho

# Check if `git procps qstat make gcc pkg-config cmake` are installed
which git >/dev/null || nqecho "The package 'git' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which procps >/dev/null || nqecho "The package 'procps' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which qstat >/dev/null || nqecho "The package 'qstat' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which make >/dev/null || nqecho "The package 'make' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which gcc >/dev/null || nqecho "The package 'gcc' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which pkg-config >/dev/null || nqecho "The package 'pkg-config' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again."
which cmake >/dev/null || nqecho "The package 'cmake' is not installed. Please install it and run ./nquakesv-build-mvdsv.sh and ./nquakesv-build-ktx.sh again.";

nqecho "Optionally, edit the top of nquakesv-build-mvdsv.sh and nquakesv-build-ktx.sh as needed to change repo/branch from which to build, and run them again"
}

# Start servers
./start_servers.sh

nqecho
nqecho "Installation complete. Please read the README in ${directory}."
nqecho "Please make sure to accept UDP ports 28501-$((28500+${ports})) (mvdsv), UDP port 30000 (qwfwd) and TCP/UDP port 28000 (qtv/hub)."
nqecho "For example on debian, `sudo apt install ufw && sudo ufw allow ssh && sudo ufw allow 28000/tcp && sudo ufw allow 28000/udp && sudo ufw allow 28501:28505/udp && sudo ufw allow 30000/udp && sudo ufw enable`"
nqecho
nqecho "Optionally, edit ktx/configs/usermodes/default.cfg and change `set k_teamoverlay` to 1."
nqecho "Optionally, edit ktx/ktx.cfg and uncomment the k_admincode line and set your own admincode."
nqecho
nqecho "Run `./stop_servers.sh && ./start_servers.sh` after any configuration changes or new builds."
nqecho "Run `./update.sh or ./update_maps.sh occasionally to update scripts/maps"
nqecho

exit 0
