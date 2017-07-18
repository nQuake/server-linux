#!/bin/bash

# nQuakesv config update bash script (for Linux)
# by Empezar

# Parameters: --random-mirror --restart --no-restart --sure

# Check if unzip is installed
unzip=`which unzip`
if [ "$unzip"  = "" ]
then
        echo "Unzip is not installed. Please install it and run the nQuakesv installation again."
        exit
fi

# Change folder to nQuakesv
cd `cat ~/.nquakesv/install_dir`

echo
echo "Welcome to the nQuakesv config updater"
echo "======================================"
echo

# Download nquake.ini
mkdir tmp
cd tmp
wget --inet4-only -q -O nquake.ini http://nquake.sourceforge.net/nquake.ini
if [ -s "nquake.ini" ]
then
        echo foo >> /dev/null
else
        echo "Error: Could not download nquake.ini. Better luck next time. Exiting."
	cd ..
	rm -rf tmp
        exit
fi

# List all the available mirrors
echo "From what mirror would you like to download the configs?"
grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
if [ "$1" == "--random-mirror" ] || [ "$2" == "--random-mirror" ] || [ "$3" == "--random-mirror" ] || [ "$4" == "--random-mirror" ]; then
        mirror=""
else
        read -p "Enter mirror number [random]: " mirror
fi
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
echo

# Download maps
echo "=== Downloading ==="
wget --inet4-only -O sv-configs.zip $mirror/sv-configs.zip

# Terminate installation if not all packages were downloaded
if [ -s "sv-configs.zip" ]
then
        if [ "$(du sv-configs.zip | cut -f1)" \> "0" ]
        then
                echo foo >> /dev/null
        else
                echo "Error: The configs failed to download. Better luck next time. Exiting."
                cd ..
		rm -rf tmp
                exit
        fi
else
        echo "Error: The configs failed to download. Better luck next time. Exiting."
	cd ..
	rm -rf tmp
        exit
fi

# Ask to restart servers
if [ "$1" == "--restart" ] || [ "$2" == "--restart" ] || [ "$3" == "--restart" ] || [ "$4" == "--restart" ]; then
        restart="y"
else
        if [ "$1" == "--no-restart" ] || [ "$2" == "--no-restart" ] || [ "$3" == "--no-restart" ] || [ "$4" == "--no-restart" ]; then
                restart="n"
        else
                read -p "Do you want the script to stop and restart your servers and proxies? (y/n) [n]: " restart
                echo
        fi
fi

# Install updates
echo "=== Installing ==="
echo -n "* Extracting configs..."
unzip -qqo sv-configs.zip 2> /dev/null;echo "done"
echo -n "* Setting permissions..."
find . -type f -exec chmod -f 644 {} \;
find . -type d -exec chmod -f 755 {} \;
echo "done"
# Convert DOS files to UNIX
echo -n "* Converting DOS files to UNIX..."
for file in $(find .)
do
        if [ -f "$file" ]
        then
                awk '{ sub("\r$", ""); print }' $file > /tmp/.nquakesv.tmp
                mv /tmp/.nquakesv.tmp $file
        fi
done
echo "done"

# Stop servers
if [ "$restart" == "y" ]
then
        echo "* Stopping servers and proxies...done"
        ../stop_servers.sh
fi

# Move configs into place
if [ "$1" == "--sure" ] || [ "$2" == "--sure" ] || [ "$3" == "--sure" ] || [ "$4" == "--sure" ]; then
        sure="y"
else
        echo;echo "Your old configuration files will now be removed and replaced. The settings that you picked during setup will be untouched."
        echo;read -p "Are you sure you want to continue? (y/n) [y]: " sure
        echo
fi
if [ "$sure" != "n" ]
then
        echo -n "* Moving configs into place..."
        rm -rf ../ktx/configs ../ktx/modes
        mv ktx/configs ../ktx/configs
        mv ktx/modes ../ktx/modes
        mv ktx/* ../ktx/
        echo "done"
fi

# Remove temporary directory
echo -n "* Cleaning up..."
cd ..
rm -rf tmp
echo "done"

# Restart servers
if [ "$restart" == "y" ]
then
        echo "* Starting servers and proxies...done"
        ./start_servers.sh > /dev/null 2>&1
fi

echo;echo "Update complete."
echo
