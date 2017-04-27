#!/bin/bash
# nQuakesv Installer Script v1.5 (for Linux)
# by Empezar & dimman
nqversion="1.5"

# Usage info
show_help() {
cat << EOF
usage: install_nquakesv.sh [-h|--help] [-n|--non-interactive] [-h|--hostname=<hostname>]
                           [-p|--number-of-ports=<count>] [-t|--qtv] [-f|--qwfwd]
                           [-a|--admin=<name>] [-e|--admin-email=<email>]
                           [-r|--rcon-password=<password>] [-y|--qtv-password=<password>]
                           [-s|--search-pak[=<path>]] [-q|--quiet] [-qq|--extra-quiet] [TARGETDIR]

    -h, --help              display this help and exit.
    -n, --non-interactive   non-interactive mode (use defaults or command line
                            parameters, and do not prompt for anything).
    -q, --quiet             do not output informative messages during setup. this
                            will not silence messages that require interaction.
    -qq, --extra-quiet      do not output errors during setup.
    -h, --hostname          hostname of the server.
    -p, --number-of-ports   number of ports to run.
    -t, --qtv               install qtv.
    -f, --qwfwd             install qwfwd proxy.
    -a, --admin             administrator name
    -e, --admin-email       administrator e-mail.
    -r, --rcon-password     rcon password.
    -y, --qtv-password      qtv password.
    -s, --search-pak        search for pak1.pak during setup, specify a directory
                            to start searching there instead of in home folder.
EOF
}

created=0
nondefaultrcon=

# Parse command line parameters
noninteractive=""
quiet=""
extraquiet=""
nqinstalldir=""
nqhostname=""
nqnumports=""
nqinstallqtv=""
nqinstallqwfwd=""
nqipaddr=""
nqadmin=""
nqemail=""
nqrcon=""
nqqtvpassword=""
nqsearchpak=""
searchdir=""

for i in "$@"
do
case $i in
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
    -h=*|--hostname=*)
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
    -l=*|--listen-address=*)
        nqipaddr="${i#*=}"
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
    *)
        nqinstalldir="${i#*=}"
        ;;
esac
done

# Defaults (use cmdline parameters)
defaultdir=$([ ! -z "$nqinstalldir" ] && echo $nqinstalldir || echo "~/nquakesv")
defaulthostname=$([ ! -z "$nqhostname" ] && echo $nqhostname || echo "KTX Allround")
defaultports=$([ ! -z "$nqnumports" ] && echo $nqnumports || echo 4)
defaultqtv=$([ ! -z "$nqinstallqtv" ] && echo $nqinstallqtv || echo "n")
defaultqwfwd=$([ ! -z "$nqinstallqwfwd" ] && echo $nqinstallqwfwd || echo "n")
defaultadmin=$([ ! -z "$nqadmin" ] && echo $nqadmin || echo $USER)
defaultemail=$([ ! -z "$nqemail" ] && echo $nqemail || echo "$defaultadmin@example.com")
defaultrcon=$([ ! -z "$nqrcon" ] && echo $nqrcon || echo "changeme")
defaultqtvpass=$([ ! -z "$nqqtvpassword" ] && echo $nqqtvpassword || echo "changeme")
defaultsearchoption=$([ "$nqsearchpak" = "y" ] && echo "y" || echo "n")
defaultsearchdir=$([ "$defaultsearchoption" = "y" ] && [ ! -z "$searchdir" ] && echo $searchdir || echo "~/")

error() {
	printf "ERROR: %s\n" "$*"
	[ "$created" -ne 1 ] || {
		cd
		nqeecho "The directory $directory is about to be removed, press ENTER to confirm or CTRL+C to exit."
		read dummy
		rm -rf $directory
	}
	exit 1
}

nqecho() {
        nqnecho "$* \n"
}

nqnecho() {
        [ -z "$quiet" ] && printf "$*"
}

nqeecho() {
        [ -z "$extraquiet" ] && printf "$*"
}

nqiecho() {
        [ -z "$noninteractive" ] && nqecho $*
}

nqwget() {
        [ ! -z "$quiet" ] && {
                wget $* >/dev/null 2>&1
        } || {
                wget $*
        }
}

# Check if unzip is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the nQuakesv installation again."

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the nQuakesv installation again."

# Check if wget is installed
which wget >/dev/null || error "The package 'wget' is not installed. Please install it and run the nQuakesv installation again."

nqecho
nqecho "Welcome to the nQuakesv v$nqversion installation"
nqecho "========================================="
nqiecho
nqiecho "Press ENTER to use [default] option."
nqiecho

# Interactive stuff
if [ -z "$noninteractive" ]; then
	# Install dir
	printf "Where do you want to install nQuakesv? [$defaultdir]: "
	read directory
	eval directory=$directory

	# Hostname
	printf "Enter a descriptive hostname [$defaulthostname]: "
	read hostname

	# IP/dns
        [ -z "$nqipaddr" ] && {
                printf "Enter your server's DNS. [use external IP]: "
        } || {
                printf "Enter your server's DNS. [$nqipaddr]: "
        }
	read hostdns

	# Ports
	printf "How many ports of KTX do you wish to run (max 10)? [$defaultports]: "
	read ports

	# Rcon
	printf "What should the rcon password be? [$defaultrcon]: "
	read rcon
	[ -z "$rcon" ] && [ -z "$nondefaultrcon" ] && {
		nqecho
		nqecho "Your rcon has been set to $defaultrcon. This is an enormous security risk."
		nqecho "To change this, edit $directory/ktx/pwd.cfg"
		nqecho
	}

	# QTV
	printf "Do you wish to run a qtv proxy? (y/n) [$defaultqtv]: "
	read qtv
	if [ "$qtv" = "y" ]; then
		printf "What should the qtv admin password be? [$defaultqtvpass]: "
		read qtvpass
		[ -z "$qtvpass" ] && {
			nqecho
			nqecho "Your qtv password has been set to $defaultqtvpass. This is not recommended."
			nqecho "To change this, edit $directory/qtv/qtv.cfg"
			nqecho
		}
	fi

	# QWFWD
	printf "Do you wish to run a qwfwd proxy? (y/n) [$defaultqwfwd]: "
	read qwfwd

	# Admin name
	printf "Who is the admin of this server? [$defaultadmin]: "
	read admin

	# Admin email
	printf "What is the admin's e-mail? [$defaultemail]: "
	read email

	# Search for Pak1
	printf "Do you want setup to search for pak1.pak? (y/n) [$defaultsearchoption]: "
	read search
	if [[ "$search" == "y" || ( "$defaultsearchoption" == "y" && "$search" == "" ) ]]; then
		printf "Enter path to search for pak1.pak (subdirs are also searched) [$defaultsearchdir]: "
		read path
	fi
fi

review=
nqecho
nqiecho "Please review the following settings:"
nqecho "========================================="
# Set defaults if nothing was entered (non-interactive mode or just use defaults)
[ -z "$directory" ] && eval directory=$defaultdir
[ -z "$hostname" ] && hostname=$defaulthostname
[ -z "$hostdns" ] && hostdns=$nqipaddr
[ -z "$ports" ] && ports=$defaultports
[ -z "$rcon" ] && rcon=$defaultrcon
[ -z "$qtv" ] && qtv=$defaultqtv
[ -z "$qtvpass" ] && qtvpass=$defaultqtvpass
[ -z "$qwfwd" ] && qwfwd=$defaultqwfwd
[ -z "$admin" ] && admin=$defaultadmin
[ -z "$email" ] && email=$defaultemail
[ -z "$search" ] && search=$defaultsearchoption
[ -z "$path" ] && path=$defaultsearchdir

nqecho "Install directory:   $directory"
nqecho "Hostname:            $hostname"
nqnecho "Listen address:      "
[ -z "$hostdns" ] && nqecho "<resolve address>" || nqecho "$hostdns"
nqecho "Number of ports:     $ports"
nqecho "RCON password:       $rcon"
nqnecho "Install QTV:         "
[ "$qtv" = "y" ] && nqecho "yes (password: $qtvpass)" || nqecho "no"
nqnecho "Install QWFWD:       "
[ "$qwfwd" = "y" ] && nqecho "yes" || nqecho "no"
nqecho "Admin:               $admin <$email>"
nqnecho "Search for pak1:     "
[ "$search" = "y" ] && nqecho "$path" || nqecho "<do not search>"
nqecho "========================================="

[ -z "$noninteractive" ] && {
        nqecho
        nqecho "Press any key to continue..."
        read review
}

# Fix ports
[ "$ports" -gt 10 ] && ports=10
[ "$ports" -lt 1 ] && ports=1

nqecho
nqecho "Installation proceeding..."

# Create the nQuakesv folder
if [ -d "$directory" ]; then
	if [ -w "$directory" ]; then
		created=0
	else
		error "You do not have write access to '$directory'. Exiting."
	fi
else
	if [ -e "$directory" ]; then
		error "'$directory' already exists but is a file, not a directory. Exiting."
		exit
	else
		mkdir -p $directory 2>/dev/null || error "Failed to create install dir: '$directory'"
		created=1
	fi
fi
if [ -w "$directory" ]; then
	cd $directory
	directory=$(pwd)
else
	error "You do not have write access to $directory. Exiting."
fi

# Search for pak1.pak
pak=
if [ "$search" = "y" ]; then
	eval path=$path
	pak=$(echo $(find $path -type f -iname "pak1.pak" -size 33M -exec echo {} \; 2> /dev/null) | cut -d " " -f1)
	if [ "$pak" != "" ]; then
		nqecho
                nqecho "* Found at location $pak"
	else
		nqecho
                nqecho "* Could not find pak1.pak"
	fi
fi
nqecho

# Download nquake.ini
nqwget --inet4-only -q -O nquake.ini https://raw.githubusercontent.com/nQuake/client-win32/master/etc/nquake.ini || error "Failed to download nquake.ini"
[ -s "nquake.ini" ] || error "Downloaded nquake.ini but file is empty?! Exiting."

# List all the available mirrors
if [ -z "$noninteractive" ]; then
	printf "From what mirror would you like to download nQuakesv?"
	grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
	printf "Enter mirror number [random]: "
	read mirror
	mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
        nqecho
fi
[ -z "$mirror" ] && {
        nqnecho "Using mirror: "
	range=$(expr$(grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
	while [ -z "$mirror" ]
	do
		number=$RANDOM
		let "number %= $range"
		mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
		mirrorname=$(grep "^$number=\".*" nquake.ini | cut -d "\"" -f2)
	done
	nqecho "$mirrorname"
}
mkdir -p id1
nqecho

# Find out what architecture to use
binary=$(uname -i)

# Download all the packages
nqecho "=== Downloading ==="
nqwget --inet4-only -O qsw106.zip $mirror/qsw106.zip || error "Failed to download $mirror/qsw106.zip"
nqwget --inet4-only -O sv-gpl.zip $mirror/sv-gpl.zip || error "Failed to download $mirror/sv-gpl.zip"
nqwget --inet4-only -O sv-non-gpl.zip $mirror/sv-non-gpl.zip || error "Failed to download $mirror/sv-non-gpl.zip"
nqwget --inet4-only -O sv-configs.zip $mirror/sv-configs.zip || error "Failed to download $mirror/sv-configs.zip"
if [ "$binary" = "x86_64" ]
then
	nqwget --inet4-only -O sv-bin-x64.zip $mirror/sv-bin-x64.zip || error "Failed to download $mirror/sv-bin-x64.zip"
	[ -s "sv-bin-x64.zip" ] || error "Downloaded sv-bin-x64.zip but file is empty?!"
else
	nqwget --inet4-only -O sv-bin-x86.zip $mirror/sv-bin-x86.zip || error "Failed to download $mirror/sv-bin-x86.zip"
	[ -s "sv-bin-x86.zip" ] || error "Downloaded sv-bin-x86.zip but file is empty?!"
fi

[ -s "qsw106.zip" ] || error "Downloaded qwsv106.zip but file is empty?!"
[ -s "sv-gpl.zip" ] || error "Downloaded sv-gpl.zip but file is empty?!"
[ -s "sv-non-gpl.zip" ] || error "Downloaded sv-non-gpl.zip but file is empty?!"
[ -s "sv-configs.zip" ] || error "Downloaded sv-configs.zip but file is empty?!"


# Get remote IP address
nqnecho "Resolving external IP address... "
remote_ip=$(curl -s http://myip.dnsomatic.com)
[ -n "$hostdns" ] || hostdns=$remote_ip
nqecho "Resolved: $remote_ip"
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
if [ "$binary" = "x86_64" ]
then
	(unzip -qqo sv-bin-x64.zip 2>/dev/null && nqecho done) || nqecho fail
else
	(unzip -qqo sv-bin-x86.zip 2>/dev/null && nqecho done) || nqecho fail
fi
nqnecho "* Extracting nQuakesv configuration files..."
(unzip -qqo sv-configs.zip 2>/dev/null && nqecho done) || nqecho fail
[ -z "$pak" ] || {
	nqecho "* Copying pak1.pak..."
	(cp $pak $directory/id1/pak1.pak 2>/dev/null && nqecho done) || nqecho fail
}
nqecho

# Rename files
nqecho "=== Cleaning up ==="
nqnecho "* Renaming files..."
(mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2>/dev/null && rm -rf $directory/ID1 && nqecho done) || nqecho fail

# Remove distribution files
nqnecho "* Removing distribution files..."
(rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x86.zip $directory/sv-bin-x64.zip $directory/nquake.ini && nqecho done) || nqecho fail

# Convert DOS files to UNIX
nqnecho "* Converting DOS files to UNIX..."
for file in $(find $directory -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
	[ ! -f "$file" ] || sed -i 's/^M//g' $file
done
nqecho "done"

# Set the correct permissions
nqnecho "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
chmod -f +x $directory/mvdsv 2>/dev/null
chmod -f +x $directory/ktx/mvdfinish.qws 2>/dev/null
chmod -f +x $directory/qtv/qtv.bin 2>/dev/null
chmod -f +x $directory/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x $directory/*.sh 2>/dev/null
chmod -f +x $directory/run/*.sh 2>/dev/null
chmod -f +x $directory/addons/*.sh 2>/dev/null
nqecho "done"

# Update configuration files
nqnecho "* Updating configuration files..."
mkdir -p ~/.nquakesv
echo $directory > ~/.nquakesv/install_dir
echo $hostname > ~/.nquakesv/hostname
echo $hostdns > ~/.nquakesv/hostdns
echo $remote_ip > ~/.nquakesv/ip
echo "$admin <$email>" > ~/.nquakesv/admin
#/start_servers.sh
safe_pattern=$(printf "%s\n" "$directory" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_PATH/${safe_pattern}/g" $directory/start_servers.sh
#/ktx/pwd.cfg
safe_pattern=$(printf "%s\n" "$rcon" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_RCON/${safe_pattern}/g" $directory/ktx/pwd.cfg
#/qtv/qtv.cfg
if [ "$qtv" = "y" ]
then
	safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/qtv/qtv.cfg
	safe_pattern=$(printf "%s\n" "$qtvpass" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_QTVPASS/${safe_pattern}/g" $directory/qtv/qtv.cfg
	cd qtv
	ln -sf ../ktx/demos demos
fi
#/qwfwd/qwfwd.cfg
if [ "$qwfwd" = "y" ]
then
	safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/qwfwd/qwfwd.cfg
fi
nqecho "done"

# Fix port files etc
nqnecho "* Adjusting amount of ports..."
i=1
while [ $i -le $ports ]; do
	# Fix port number
	if [ $i -gt 9 ]; then
		port=285$i
	else
		port=2850$i
	fi
	# Copy port scripts/configs
	cp $directory/run/portx.sh $directory/run/port$i.sh
	cp $directory/ktx/portx.cfg $directory/ktx/port$i.cfg
	# Fix shell scripts
	safe_pattern=$(printf "%s\n" "./mvdsv -port $port -game ktx +exec port$i.cfg" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_RUN_MVDSV/${safe_pattern}/g" $directory/run/port$i.sh
	# Fix /ktx/port1-10.cfg
	safe_pattern=$(printf "%s\n" "$hostname #$i" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/ktx/port$i.cfg
	safe_pattern=$(printf "%s\n" "$admin <$email>" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_ADMIN/${safe_pattern}/g" $directory/ktx/port$i.cfg
	safe_pattern=$(printf "%s\n" "$remote_ip:$port" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/ktx/port$i.cfg
	safe_pattern=$(printf "%s\n" "$port" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_PORT/${safe_pattern}/g" $directory/ktx/port$i.cfg
	# Fix /qtv/qtv.cfg
	echo "qtv $hostdns:$port" >> $directory/qtv/qtv.cfg
	# Fix start_servers.sh script
	echo >> $directory/start_servers.sh
	echo "printf \"* Starting mvdsv (port $port)...\"" >> $directory/start_servers.sh
	echo "if ps ax | grep -v grep | grep \"mvdsv -port $port\" > /dev/null" >> $directory/start_servers.sh
	echo "then" >> $directory/start_servers.sh
	echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
	echo "else" >> $directory/start_servers.sh
	echo "./run/port$i.sh > /dev/null &" >> $directory/start_servers.sh
	echo "echo \"[OK]\"" >> $directory/start_servers.sh
	echo "fi" >> $directory/start_servers.sh
	# Fix stop_servers.sh script
	echo >> $directory/stop_servers.sh
	echo "# Kill $port" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/port$i.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"mvdsv -port $port\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	i=$((i+1))
done
rm -rf $directory/ktx/portx.cfg
rm -rf $directory/run/portx.sh
nqecho "done"

# Add QTV
if [ "$qtv" = "y" ]
then
	nqnecho "* Adding qtv to start/stop scripts..."
	# start_servers.sh
	echo >> $directory/start_servers.sh
	echo "printf \"* Starting qtv (port 28000)...\"" >> $directory/start_servers.sh
	echo "if ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" > /dev/null" >> $directory/start_servers.sh
	echo "then" >> $directory/start_servers.sh
	echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
	echo "else" >> $directory/start_servers.sh
	echo "./run/qtv.sh > /dev/null &" >> $directory/start_servers.sh
	echo "echo \"[OK]\"" >> $directory/start_servers.sh
	echo "fi" >> $directory/start_servers.sh
	# stop_servers.sh
	echo >> $directory/stop_servers.sh
	echo "# Kill QWFWD" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/qwfwd.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"qwfwd.bin\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	nqecho "done"
else
	nqnecho "* Removing qtv files..."
	(rm -rf $directory/qtv $directory/run/qtv.sh && nqecho done) || nqecho fail
fi

# Add/remove qwfwd
if [ "$qwfwd" = "y" ]
then
	# start_servers.sh
	nqnecho "* Adding qwfwd to start/stop scripts..."
	echo >> $directory/start_servers.sh
	echo "echo -n \"* Starting qwfwd (port 30000)...\"" >> $directory/start_servers.sh
	echo "if ps ax | grep -v grep | grep \"qwfwd.bin\" > /dev/null" >> $directory/start_servers.sh
	echo "then" >> $directory/start_servers.sh
	echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
	echo "else" >> $directory/start_servers.sh
	echo "./run/qwfwd.sh > /dev/null &" >> $directory/start_servers.sh
	echo "echo \"[OK]\"" >> $directory/start_servers.sh
	echo "fi" >> $directory/start_servers.sh
	# stop_servers.sh
	echo >> $directory/stop_servers.sh
	echo "# Kill QWFWD" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/qwfwd.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"qwfwd.bin\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	nqecho "done"
else
	nqnecho "* Removing qwfwd files..."
	(rm -rf $directory/qwfwd $directory/run/qwfwd.sh && nqecho done) || nqecho fail
fi

nqecho
nqecho "To make sure your servers are always running, type \"crontab -e\" and add the following:"
nqecho
nqecho "*/10 * * * * $directory/start_servers.sh >/dev/null 2>&1"
nqecho
nqecho "Installation complete. Please read the README in $directory."
nqecho

exit 0