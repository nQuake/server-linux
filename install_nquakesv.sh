#!/bin/bash

# nQuakesv Bash Installer Script v1.0 (for Linux)
# by Empezar

# Check if unzip is installed
unzip=`which unzip`
if [ "$unzip"  = "" ]
then
	echo "The package 'unzip' is not installed. Please install it and run the nQuakesv installation again."
	exit
fi

# Check if curl is installed
curl=`which curl`
if [ "$curl"  = "" ]
then
        echo "The package 'curl' is not installed. Please install it and run the nQuakesv installation again."
        exit
fi

echo
echo "Welcome to the nQuakesv v1.0 installation"
echo "========================================="
echo
echo "Press ENTER to use [default] option."
echo

# Create the nQuake folder
defaultdir="~/nquakesv"
read -p "Where do you want to install nQuakesv? [$defaultdir]: " directory
if [ "$directory" = "" ]
then
        directory=$defaultdir
fi
eval directory=$directory
if [ -d "$directory" ]
then
	if [ -w "$directory" ]
	then
		created=0
	else
		echo;echo "Error: You do not have write access to $directory. Exiting."
		exit
	fi
else
	if [ -e "$directory" ]
	then
		echo;echo "Error: $directory already exists and is a file, not a directory. Exiting."
		exit
	else
		mkdir -p $directory 2> /dev/null
		created=1
	fi
fi
if [ -d "$directory" ] && [ -w "$directory" ]
then
	cd $directory
	directory=$(pwd)
else
	echo;echo "Error: You do not have write access to $directory. Exiting."
	exit
fi

# How many ports to run
defaultports=4
read -p "How many ports do you wish to run (max 4)? [$defaultports]: " ports
if [ "$ports" = "" ]
then
        ports=$defaultports
fi

# Hostname
defaulthostname="KTX Allround"
read -p "Enter a descriptive hostname [$defaulthostname]: " hostname
if [ "$hostname" = "" ]
then
        hostname=$defaulthostname
fi

# Run qtv?
read -p "Do you wish to run a qtv proxy? (y/n) [y]: " qtv
if [ "$qtv" = "" ]
then
        qtv="y"
fi

# Run qwfwd?
read -p "Do you wish to run a qwfwd proxy? (y/n) [y]: " qwfwd
if [ "$qwfwd" = "" ]
then
        qwfwd="y"
fi

# Admin name
defaultadmin=$USER
read -p "Who is the admin of this server? [$defaultadmin]: " admin
if [ "$admin" = "" ]
then
        admin=$defaultadmin
fi

# Admin email
defaultemail="$admin@example.com"
read -p "What is the admin's e-mail? [$defaultemail]: " email
if [ "$email" = "" ]
then
        admin=$defaultemail
fi

# Rcon
defaultrcon="changeme"
read -p "What should the rcon password be? [$defaultrcon]: " rcon
if [ "$rcon" = "" ]
then
	echo
	echo "Your rcon has been set to $defaultrcon. This is an enormous security risk."
	echo "To change this, edit $directory/ktx/pwd.cfg"
	echo
        rcon=$defaultrcon
fi

if [ "$qtv" == "y" ]
then
	# Qtv password
	defaultqtvpass="123456"
	read -p "What should the qtv password be? [$defaultqtvpass]: " qtvpass
	if [ "$qtvpass" = "" ]
	then
	        echo
	        echo "Your qtv password has been set to $defaultqtvpass. This is not recommended."
	        echo "To change this, edit $directory/qtv/qtv.cfg"
	        echo
	        qtvpass=$defaultqtvpass
	fi
fi

# Search for pak1.pak
defaultsearchdir="~/"
pak=""
read -p "Do you want setup to search for pak1.pak? (y/n) [n]: " search
if [ "$search" = "y" ]
then
	read -p "Enter path to search for pak1.pak (subdirs are also searched) [$defaultsearchdir]: " path
	if [ "$path" = "" ]
	then
		path=$defaultsearchdir
	fi
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
wget --inet4-only -q -O nquake.ini http://nquake.sourceforge.net/nquake.ini
if [ -s "nquake.ini" ]
then
	echo foo >> /dev/null
else
	echo "Error: Could not download nquake.ini. Better luck next time. Exiting."
        if [ "$created" = "1" ]
        then
                cd
		read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
                rm -rf $directory
        fi
	exit
fi

# List all the available mirrors
echo "From what mirror would you like to download nQuakesv?"
grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
read -p "Enter mirror number [random]: " mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
if [ "$mirror" = "" ]
then
        echo;echo -n "* Using mirror: "
        RANGE=$(expr$(grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ "$mirror" = "" ]
        do
                number=$RANDOM
                let "number %= $RANGE"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nquake.ini | cut -d "=" -f2)
		mirrorname=$(grep "^$number=\".*" nquake.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
fi
mkdir -p id1
echo;echo

# Find out what architecture to use
binary=`uname -i`

# Download all the packages
echo "=== Downloading ==="
wget --inet4-only -O qsw106.zip $mirror/qsw106.zip
if [ -s "qsw106.zip" ]
then
	if [ "$(du qsw106.zip | cut -f1)" \> "0" ]
	then
	        wget --inet4-only -O sv-gpl.zip $mirror/sv-gpl.zip
	fi
fi
if [ -s "sv-gpl.zip" ]
then
	if [ "$(du sv-gpl.zip | cut -f1)" \> "0" ]
	then
		wget --inet4-only -O sv-non-gpl.zip $mirror/sv-non-gpl.zip
	fi
fi
if [ -s "sv-non-gpl.zip" ]
then
	if [ "$(du sv-non-gpl.zip | cut -f1)" \> "0" ]
	then
		wget --inet4-only -O sv-configs.zip $mirror/sv-configs.zip
	fi
fi
if [ -s "sv-configs.zip" ]
then
        if [ "$(du sv-configs.zip | cut -f1)" \> "0" ]
        then
                if [ "$binary" == "x86_64" ]
                then
                        wget --inet4-only -O sv-bin-x64.zip $mirror/sv-bin-x64.zip
                else
                        wget --inet4-only -O sv-bin-x86.zip $mirror/sv-bin-x86.zip
                fi
        fi
fi

# Get remote IP address
echo "Fetching remote IP address..."
echo
remote_ip=`curl http://myip.dnsomatic.com`
echo

# Terminate installation if not all packages were downloaded
if [ -s "sv-bin-x86.zip" -o -s "sv-bin-x64.zip" ]
then
	if [ -s "sv-bin-x86.zip" ]
	then
		if [ "$(du sv-bin-x86.zip | cut -f1)" \> "0" ]
		then
			echo foo >> /dev/null
		else
			echo "Error: Some distribution files failed to download. Better luck next time. Exiting."
			rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x86.zip $directory/nquake.ini
			if [ "$created" = "1" ]
			then
				cd
				read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
				rm -rf $directory
			fi
			exit
		fi
	else
		if [ "$(du sv-bin-x64.zip | cut -f1)" \> "0" ]
		then
			echo foo >> /dev/null
		else
			echo "Error: Some distribution files failed to download. Better luck next time. Exiting."
			rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x64.zip $directory/nquake.ini
			if [ "$created" = "1" ]
			then
				cd
				read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
				rm -rf $directory
			fi
			exit
		fi
	fi
else
	echo "Error: Some distribution files failed to download. Better luck next time. Exiting."
	rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x86.zip $directory/sv-bin-x64.zip $directory/nquake.ini
	if [ "$created" = "1" ]
	then
		cd
		read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
		rm -rf $directory
	fi
	exit
fi

# Extract all the packages
echo "=== Installing ==="
echo -n "* Extracting Quake Shareware..."
unzip -qqo qsw106.zip ID1/PAK0.PAK 2> /dev/null;echo "done"
echo -n "* Extracting nQuakesv setup files (1 of 2)..."
unzip -qqo sv-gpl.zip 2> /dev/null;echo "done"
echo -n "* Extracting nQuakesv setup files (2 of 2)..."
unzip -qqo sv-non-gpl.zip 2> /dev/null;echo "done"
echo -n "* Extracting nQuakesv binaries..."
if [ "$binary" == "x86_64" ]
then
        unzip -qqo sv-bin-x64.zip 2> /dev/null;echo "done"
else
        unzip -qqo sv-bin-x86.zip 2> /dev/null;echo "done"
fi
echo -n "* Extracting nQuakesv configuration files..."
unzip -qqo sv-configs.zip 2> /dev/null;echo "done"
if [ "$pak" != "" ]
then
	echo -n "* Copying pak1.pak..."
	cp $pak $directory/id1/pak1.pak 2> /dev/null;echo "done"
	rm -rf $directory/id1/maps $directory/id1/sound $directory/id1/progs $directory/id1/README
fi
echo

# Rename files
echo "=== Cleaning up ==="
echo -n "* Renaming files..."
mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2> /dev/null
rm -rf $directory/ID1
echo "done"

# Remove distribution files
echo -n "* Removing distribution files..."
rm -rf $directory/qsw106.zip $directory/sv-gpl.zip $directory/sv-non-gpl.zip $directory/sv-configs.zip $directory/sv-bin-x86.zip $directory/sv-bin-x64.zip $directory/nquake.ini
echo "done"

# Convert DOS files to UNIX
echo -n "* Converting DOS files to UNIX..."
for file in $(find $directory -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
	if [ -f "$file" ]
	then
	        awk '{ sub("\r$", ""); print }' $file > /tmp/.nquakesv.tmp
        	mv /tmp/.nquakesv.tmp $file
	fi
done
echo "done"

# Set the correct permissions
echo -n "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
chmod -f +x $directory/mvdsv 2> /dev/null
chmod -f +x $directory/ktx/mvdfinish.qws 2> /dev/null
chmod -f +x $directory/qtv/qtv.bin 2> /dev/null
chmod -f +x $directory/qwfwd/qwfwd.bin 2> /dev/null
chmod -f +x $directory/*.sh 2> /dev/null
chmod -f +x $directory/run/*.sh 2> /dev/null
echo "done"

# Update configuration files
echo -n "* Updating configuration files..."
mkdir -p ~/.nquakesv
rm -rf ~/.nquakesv/install_dir
echo $directory >> ~/.nquakesv/install_dir
#/start_servers.sh
safe_pattern=$(printf "%s\n" "$directory" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_PATH/${safe_pattern}/g" $directory/start_servers.sh
#/ktx/pwd.cfg
safe_pattern=$(printf "%s\n" "$rcon" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_RCON/${safe_pattern}/g" $directory/ktx/pwd.cfg
#/ktx/port1-4.cfg
safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/ktx/port1.cfg
sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/ktx/port2.cfg
sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/ktx/port3.cfg
sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/ktx/port4.cfg
safe_pattern=$(printf "%s\n" "$admin <$email>" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_ADMIN/${safe_pattern}/g" $directory/ktx/port1.cfg
sed -i "s/NQUAKESV_ADMIN/${safe_pattern}/g" $directory/ktx/port2.cfg
sed -i "s/NQUAKESV_ADMIN/${safe_pattern}/g" $directory/ktx/port3.cfg
sed -i "s/NQUAKESV_ADMIN/${safe_pattern}/g" $directory/ktx/port4.cfg
safe_pattern=$(printf "%s\n" "$remote_ip" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/ktx/port1.cfg
sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/ktx/port2.cfg
sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/ktx/port3.cfg
sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/ktx/port4.cfg
#/qtv/qtv.cfg
if [ "$qtv" == "y" ]
then
	safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/qtv/qtv.cfg
	safe_pattern=$(printf "%s\n" "$remote_ip" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_IP/${safe_pattern}/g" $directory/qtv/qtv.cfg
	safe_pattern=$(printf "%s\n" "$qtvpass" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQUAKESV_QTVPASS/${safe_pattern}/g" $directory/qtv/qtv.cfg
	cd qtv
	ln -s ../ktx/demos demos
fi
#/qwfwd/qwfwd.cfg
if [ "$qwfwd" == "y" ]
then
        safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/NQUAKESV_HOSTNAME/${safe_pattern}/g" $directory/qwfwd/qwfwd.cfg
fi
echo "done"

# Remove excess ports
echo -n "* Adjusting amount of ports..."
if [ "$ports" == "4" ]
then
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28502)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28502\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port2.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28503)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28503\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port3.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28504)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28504\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port4.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        # Fix upgrade script
        # 28501
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28501\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1/${safe_pattern}/g" $directory/update_binaries.sh
        # 28502
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28502\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2/${safe_pattern}/g" $directory/update_binaries.sh
        # 28503
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_3_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28503\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_3/${safe_pattern}/g" $directory/update_binaries.sh
        # 28504
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_4_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28504\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_4/${safe_pattern}/g" $directory/update_binaries.sh
        # Fix QTV config
        sed -i "s/#NQUAKESV_PORT1//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT2//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT3//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT4//g" $directory/qtv/qtv.cfg
fi
if [ "$ports" == "3" ]
then
	rm -rf $directory/run/port4.sh $directory/ktx/port4.cfg
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28502)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28502\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port2.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28503)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28503\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port3.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        # Fix upgrade script
        # 28501
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28501\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1/${safe_pattern}/g" $directory/update_binaries.sh
        # 28502
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28502\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2/${safe_pattern}/g" $directory/update_binaries.sh
        # 28503
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_3_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28503\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_3/${safe_pattern}/g" $directory/update_binaries.sh
        # Fix QTV config
        sed -i "s/#NQUAKESV_PORT1//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT2//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT3//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT4/#/g" $directory/qtv/qtv.cfg
fi
if [ "$ports" == "2" ]
then
        rm -rf $directory/run/port3.sh $directory/ktx/port3.cfg $directory/run/port4.sh $directory/ktx/port4.cfg
        echo >> $directory/start_servers.sh
        echo "echo -n \"* Starting mvdsv (port 28502)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"mvdsv -port 28502\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/port2.sh > /dev/null &" >> $directory/start_servers.sh
        echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
	# Fix upgrade script
        # 28501
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28501\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1/${safe_pattern}/g" $directory/update_binaries.sh
        # 28502
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28502\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_2/${safe_pattern}/g" $directory/update_binaries.sh
        # Fix QTV config
        sed -i "s/#NQUAKESV_PORT1//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT2//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT3/#/g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT4/#/g" $directory/qtv/qtv.cfg
fi
if [ "$ports" == "1" ]
then
	rm -rf $directory/run/port2.sh $directory/ktx/port2.cfg $directory/run/port3.sh $directory/ktx/port3.cfg $directory/run/port4.sh $directory/ktx/port4.cfg
	# Fix upgrade script
        # 28501
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"mvdsv -port 28501\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_SERVER_1/${safe_pattern}/g" $directory/update_binaries.sh
        # Fix QTV config
        sed -i "s/#NQUAKESV_PORT1//g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT2/#/g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT3/#/g" $directory/qtv/qtv.cfg
        sed -i "s/#NQUAKESV_PORT4/#/g" $directory/qtv/qtv.cfg
fi
echo "done"

# Add QTV
if [ "$qtv" = "y" ]
then
	echo -n "* Adding qtv to startup scripts..."
	echo >> $directory/start_servers.sh
	echo "echo -n \"* Starting qtv (port 28000)...\"" >> $directory/start_servers.sh
	echo "if ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" > /dev/null" >> $directory/start_servers.sh
	echo "then" >> $directory/start_servers.sh
	echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
	echo "else" >> $directory/start_servers.sh
	echo "./run/qtv.sh > /dev/null &" >> $directory/start_servers.sh
	echo "echo \"[OK]\"" >> $directory/start_servers.sh
	echo "fi" >> $directory/start_servers.sh
        # Fix upgrade script
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_QTV_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_QTV/${safe_pattern}/g" $directory/update_binaries.sh
	echo "done"
else
	echo -n "* Removing qtv files..."
	rm -rf $directory/qtv $directory/run/qtv.sh
	echo "done"
fi

# Add/remove qwfwd
if [ "$qwfwd" = "y" ]
then
        echo -n "* Adding qwfwd to startup scripts..."
        echo >> $directory/start_servers.sh
    	echo "echo -n \"* Starting qwfwd (port 30000)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"qwfwd.bin\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/qwfwd.sh > /dev/null &" >> $directory/start_servers.sh
    	echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        # Fix upgrade script
        replace="if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_QWFWD_PID/${safe_pattern}/g" $directory/update_binaries.sh
        replace="pid=\`ps ax | grep -v grep | grep \"qwfwd.bin\" | awk '{print \$1}'\`"
        safe_pattern=$(printf "%s\n" "$replace" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/#NQUAKESV_KILL_QWFWD/${safe_pattern}/g" $directory/update_binaries.sh
        echo "done"
else
	echo -n "* Removing qwfwd files..."
        rm -rf $directory/qwfwd $directory/run/qwfwd.sh
	echo "done"
fi

echo;echo "To make sure your servers are always running, type \"crontab -e\" and add the following:"
echo;echo "*/10 * * * * $directory/start_servers.sh >/dev/null 2>&1"
echo "0 5 * * 2 $directory/update_maps.sh --random-mirror >/dev/null 2>&1"
echo;echo "The second line updates the map pool every week (optional)."
echo;echo "Installation complete."
echo
