#!/bin/bash

# nQuakesv binary update bash script (for Linux)
# by Empezar

# Parameters: --random-mirror --restart --no-restart

# Check if unzip is installed
unzip=`which unzip`
if [ "$unzip"  = "" ]
then
        echo "Unzip is not installed. Please install it and run the nQuakesv installation again."
        exit
fi

# Change folder to nQuakesv
cd `cat ~/.nquakesv/install_dir`

# Check if QTV and QWFWD is installed
if [ -d "qtv" ]; then qtv="1"; fi;
if [ -d "qwfwd" ]; then qwfwd=1; fi;

echo
echo "Welcome to the nQuakesv binary updater"
echo "======================================"
echo

# What binaries to use
binary=`uname -i`

# Download nquake.ini
mkdir tmp
cd tmp
wget --inet4-only -q -O nquake.ini http://nquake.sourceforge.net/nquake.ini
if [ -s "nquake.ini" ]
then
        echo foo >> /dev/null
else
        echo "Error: Could not download nquake.ini. Better luck next time. Exiting."
        exit
fi

# List all the available mirrors
echo "From what mirror would you like to download the binaries?"
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
mkdir -p id1
echo

# Download binaries
echo "=== Downloading ==="
if [ "$binary" == "x86_64" ]
then
        wget --inet4-only -O sv-bin-x64.zip $mirror/sv-bin-x64.zip
else
        wget --inet4-only -O sv-bin-x86.zip $mirror/sv-bin-x86.zip
fi

# Terminate installation if not all packages were downloaded
if [ -s "sv-bin-x86.zip" -o -s "sv-bin-x64.zip" ]
then
        if [ -s "sv-bin-x86.zip" ]
        then
                if [ "$(du sv-bin-x86.zip | cut -f1)" \> "0" ]
                then
                        echo foo >> /dev/null
                else
                        echo "Error: The binaries failed to download. Better luck next time. Exiting."
                        rm -rf sv-bin-x86.zip nquake.ini
                        if [ "$created" = "1" ]
                        then
                                cd ..
                                read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
                                rm -rf tmp
                        fi
                        exit
                fi
        else
                if [ "$(du sv-bin-x64.zip | cut -f1)" \> "0" ]
                then
                        echo foo >> /dev/null
                else
                        echo "Error: The binaries failed to download. Better luck next time. Exiting."
                        rm -rf sv-bin-x64.zip nquake.ini
                        if [ "$created" = "1" ]
                        then
                                cd ..
                                read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
                                rm -rf tmp
                        fi
                        exit
                fi
        fi
else
        echo "Error: The binaries failed to download. Better luck next time. Exiting."
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
# Extract binaries
echo -n "* Extracting binaries..."
if [ "$binary" == "x86_64" ]
then
	unzip -qqo sv-bin-x64.zip 2> /dev/null;echo "done"
else
	unzip -qqo sv-bin-x86.zip 2> /dev/null;echo "done"
fi

# Set the correct permissions
echo -n "* Setting permissions..."
chmod -f +x mvdsv 2> /dev/null
chmod -f -x ../mvdsv 2> /dev/null
chmod 644 ktx/qwprogs.so 2> /dev/null
if [ "$qtv" == "1" ]
then
        chmod -f +x qtv/qtv.bin 2> /dev/null
        chmod -f -x ../qtv/qtv.bin 2> /dev/null
fi
if [ "$qwfwd" == "1" ]
then
        chmod -f +x qwfwd/qwfwd.bin 2> /dev/null
        chmod -f -x ../qwfwd/qwfwd.bin 2> /dev/null
fi
echo "done"

# Stop servers
if [ "$restart" == "y" ]
then
        echo "* Stopping servers and proxies...done"
        ../stop_servers.sh
fi

# Move binaries into place
echo -n "* Moving binaries into place..."
if [ -f ../mvdsv ]; then
	mv ../mvdsv ../mvdsv.old
fi
mv mvdsv ../
if [ -f ../ktx/qwprogs.so ]; then
	mv ../ktx/qwprogs.so ../ktx/qwprogs.so.old
fi
mv ktx/qwprogs.so ../ktx/
if [ "$qtv" == "1" ]
then
	if [ -f ../qtv/qtv.bin ]; then
		mv ../qtv/qtv.bin ../qtv/qtv.bin.old
	fi
        mv qtv/qtv.bin ../qtv/
fi
if [ "$qwfwd" == "1" ]
then
	if [ -f ../qwfwd/qwfwd.bin ]; then
        	mv ../qwfwd/qwfwd.bin ../qwfwd/qwfwd.bin.old
	fi
        mv qwfwd/qwfwd.bin ../qwfwd/
fi
echo "done"

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

echo;echo "Upgrade complete."
echo
