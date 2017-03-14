#!/bin/sh

# nQuakesv Installer Script v1.4 (for Linux)
# by Empezar & dimman

defaultdir="~/nquakesv"
eval defaultdir=$defaultdir

error() {
	printf "ERROR: %s\n" "$*"
        [ "$created" -ne 1 ] || {
                cd
		echo "The directory $directory is about to be removed, press ENTER to confirm or CTRL+C to exit." 
		read dummy
                rm -rf $directory
        }
	exit 1
}

# Check if unzip is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the nQuakesv installation again."

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the nQuakesv installation again."

echo
echo "Welcome to the nQuakesv v1.4 installation"
echo "========================================="
echo
echo "Press ENTER to use [default] option."
echo

# Create the nQuake folder
printf "Where do you want to install nQuakesv? [$defaultdir]: " 
read directory

eval directory=$directory

[ ! -z "$directory" ] || eval directory=$defaultdir

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
if [ -w "$directory" ]
then
	cd $directory
	directory=$(pwd)
else
	error "You do not have write access to $directory. Exiting."
fi

# Hostname
defaulthostname="KTX Allround"
printf "Enter a descriptive hostname [$defaulthostname]: " 
read hostname
[ ! -z "$hostname" ] || hostname=$defaulthostname

# IP/dns
printf "Enter your server's DNS. [use external IP]: " 
read hostdns

# How many ports to run
defaultports=4
printf "How many ports of KTX do you wish to run (max 10)? [$defaultports]: " 
read ports
[ ! -z "$ports" ] || ports=$defaultports
[ "$ports" -le 10 ] || ports=10

# Run qtv?
printf "Do you wish to run a qtv proxy? (y/n) [y]: " 
read qtv
[ ! -z "$qtv" ] || qtv="y"

# Run qwfwd?
printf "Do you wish to run a qwfwd proxy? (y/n) [y]: " 
read qwfwd
[ ! -z "$qwfwd" ] || qwfwd="y"

# Admin name
defaultadmin=$USER

printf "Who is the admin of this server? [$defaultadmin]: " 
read admin
[ ! -z "$admin" ] || admin=$defaultadmin

# Admin email
defaultemail="$admin@example.com"
printf "What is the admin's e-mail? [$defaultemail]: " 
read email
[ ! -z "$email" ] || email=$defaultemail

# Rcon
defaultrcon="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12};echo)"
printf "What should the rcon password be? [$defaultrcon]: " 
read rcon
[ ! -z "$rcon" ] || {
	echo
	echo "Your rcon has been set to $defaultrcon. This is an enormous security risk."
	echo "To change this, edit $directory/ktx/pwd.cfg"
	echo
        rcon=$defaultrcon
}

if [ "$qtv" = "y" ]
then
	# Qtv password
	defaultqtvpass="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12};echo)"
	printf "What should the qtv admin password be? [$defaultqtvpass]: " 
	read qtvpass
	[ ! -z "$qtvpass" ] || {
	        echo
	        echo "Your qtv password has been set to $defaultqtvpass. This is not recommended."
	        echo "To change this, edit $directory/qtv/qtv.cfg"
	        echo
	        qtvpass=$defaultqtvpass
	}
fi

# Search for pak1.pak
defaultsearchdir="~/"
pak=
printf "Do you want setup to search for pak1.pak? (y/n) [y]: " 
read search
if [ -z "$search" ] || [ "$search" = "y" ]
then
	printf "Enter path to search for pak1.pak (subdirs are also searched) [$defaultsearchdir]: " 
	read path
	[ ! -z "$path" ] || path=$defaultsearchdir
	eval path=$path
	pak=$(echo $(find $path -type f -iname "pak1.pak" -size 33M -exec echo {} \; 2> /dev/null) | cut -d " " -f1)
	if [ "$pak" != "" ]
	then
		echo;echo "* Found at location $pak"
	else
		echo;echo "* Could not find pak1.pak"
	fi
fi
echo

# Download nquake.ini
wget --inet4-only -q -O nquake.ini https://raw.githubusercontent.com/nQuake/client-win32/master/etc/nquake.ini || error "Failed to download nquake.ini"
[ -s "nquake.ini" ] || error "Downloaded nquake.ini but file is empty?! Exiting."

# List all the available mirrors
echo "From what mirror would you like to download nQuakesv?"
grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
printf "Enter mirror number [random]: " 
read mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
[ -n "$mirror" ] || {
        echo;echo -n "* Using mirror: "
        range=$(expr$(grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ -z "$mirror" ]
        do
                number=$RANDOM
                let "number %= $range"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
		mirrorname=$(grep "^$number=\".*" nquake.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
}
mkdir -p id1
echo;echo

# Find out what architecture to use
binary=$(uname -i)

# Download all the packages
echo "=== Downloading ==="
wget --inet4-only -O qsw106.zip $mirror/qsw106.zip || error "Failed to download $mirror/qsw106.zip"
wget --inet4-only -O sv-gpl.zip $mirror/sv-gpl.zip || error "Failed to download $mirror/sv-gpl.zip"
wget --inet4-only -O sv-non-gpl.zip $mirror/sv-non-gpl.zip || error "Failed to download $mirror/sv-non-gpl.zip"
wget --inet4-only -O sv-configs.zip $mirror/sv-configs.zip || error "Failed to download $mirror/sv-configs.zip"
if [ "$binary" = "x86_64" ]
then
	wget --inet4-only -O sv-bin-x64.zip $mirror/sv-bin-x64.zip || error "Failed to download $mirror/sv-bin-x64.zip"
	[ -s "sv-bin-x64.zip" ] || error "Downloaded sv-bin-x64.zip but file is empty?!"
else
	wget --inet4-only -O sv-bin-x86.zip $mirror/sv-bin-x86.zip || error "Failed to download $mirror/sv-bin-x86.zip"
	[ -s "sv-bin-x86.zip" ] || error "Downloaded sv-bin-x86.zip but file is empty?!"
fi

[ -s "qsw106.zip" ] || error "Downloaded qwsv106.zip but file is empty?!"
[ -s "sv-gpl.zip" ] || error "Downloaded sv-gpl.zip but file is empty?!"
[ -s "sv-non-gpl.zip" ] || error "Downloaded sv-non-gpl.zip but file is empty?!"
[ -s "sv-configs.zip" ] || error "Downloaded sv-configs.zip but file is empty?!"


# Get remote IP address
echo "Resolving external IP address..."
echo
remote_ip=$(curl http://myip.dnsomatic.com)
[ -n "$hostdns" ] || hostdns=$remote_ip

echo

# Extract all the packages
echo "=== Installing ==="
printf "* Extracting Quake Shareware..."
(unzip -qqo qsw106.zip ID1/PAK0.PAK 2>/dev/null && echo done) || echo fail
printf "* Extracting nQuakesv setup files (1 of 2)..."
(unzip -qqo sv-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQuakesv setup files (2 of 2)..."
(unzip -qqo sv-non-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQuakesv binaries..."
if [ "$binary" = "x86_64" ]
then
        (unzip -qqo sv-bin-x64.zip 2>/dev/null && echo done) || echo fail
else
        (unzip -qqo sv-bin-x86.zip 2>/dev/null && echo done) || echo fail
fi
printf "* Extracting nQuakesv configuration files..."
(unzip -qqo sv-configs.zip 2>/dev/null && echo done) || echo fail
[ -z "$pak" ] || {
	printf "* Copying pak1.pak..."
	(cp $pak $directory/id1/pak1.pak 2>/dev/null && echo done) || echo fail
# IS THIS REALLY NECESSARY???
	rm -rf $directory/id1/maps $directory/id1/sound $directory/id1/progs $directory/id1/README || :
}
echo

# Rename files
echo "=== Cleaning up ==="
printf "* Renaming files..."
(mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2>/dev/null && rm -rf $directory/ID1 && echo done) || echo fail

# Remove distribution files
printf "* Removing distribution files..."
(rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x86.zip $directory/sv-bin-x64.zip $directory/nquake.ini && echo done) || echo fail

# Convert DOS files to UNIX
printf "* Converting DOS files to UNIX..."
for file in $(find $directory -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
	[ ! -f "$file" ] || sed -i 's///g' $file
done
echo "done"

# Set the correct permissions
printf "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
chmod -f +x $directory/mvdsv 2>/dev/null
chmod -f +x $directory/ktx/mvdfinish.qws 2>/dev/null
chmod -f +x $directory/qtv/qtv.bin 2>/dev/null
chmod -f +x $directory/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x $directory/*.sh 2>/dev/null
chmod -f +x $directory/run/*.sh 2>/dev/null
chmod -f +x $directory/addons/*.sh 2>/dev/null
echo "done"

# Update configuration files
printf "* Updating configuration files..."
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
	ln -s ../ktx/demos demos
fi
#/qwfwd/qwfwd.cfg
if [ "$qwfwd" = "y" ]
then
        safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/qwfwd/qwfwd.cfg
fi
echo "done"

# Fix port files etc
printf "* Adjusting amount of ports..."
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
echo "done"

# Add QTV
if [ "$qtv" = "y" ]
then
	printf "* Adding qtv to start/stop scripts..."
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
	echo "# Kill QTV" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/qtv.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "done"
else
	printf "* Removing qtv files..."
	(rm -rf $directory/qtv $directory/run/qtv.sh && echo done) || echo fail
fi

# Add/remove qwfwd
if [ "$qwfwd" = "y" ]
then
	# start_servers.sh
        echo -n "* Adding qwfwd to start/stop scripts..."
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
        echo "done"
else
	printf "* Removing qwfwd files..."
        (rm -rf $directory/qwfwd $directory/run/qwfwd.sh && echo done) || echo fail
fi

echo;echo "To make sure your servers are always running, type \"crontab -e\" and add the following:"
echo;echo "*/10 * * * * $directory/start_servers.sh >/dev/null 2>&1"
echo;echo "Installation complete. Please read the README in $directory."
echo
