#!/bin/bash 

#   sudo ./rpi_provision.sh <disk_device> <base_image> <network_interface> <ip> [<urls_file>]
#   <disk_device>           <----- complete path. Example: /dev/sdb
#   <base_image>            <----- complete path. Example: ~/screenly.img.gz
#   <network_interface>     <----- Name of interface. Example: eth0 or wlan0
#   <ip>                    <----- IP adress Example: 10.100.64.27
#   <urls_file>             <----- complete path. Example: ~\URLs.txt

#initialize the timer
START=$(date +%s)

#Check the number of parameters
if [ $# -lt 4 -o $# -gt 5 ]; then
  if [ $# -eq 0 ]; then
    echo 'sudo ./rpi_provision.sh <disk_device> <base_image> <network_interface> <ip> [<urls_file>]'
    exit 0
  fi
  echo 'Incorrect number of parameters'
  echo 'sudo ./rpi_provision.sh <disk_device> <base_image> <network_interface> <ip> [<urls_file>]'
  exit 1
fi

#Check the existence of disk_device
if test ! -e $1; then
  echo "The disk_device '$1' not exist"
  exit 2
fi

#Check the existence of base_image
if test ! -e $2; then
  echo "The base_image '$2' not exist"
  exit 3
fi

#Check that the interface name is correct
interface=`echo "$3" | sed -e 's/.$//'`
if [ "$interface" != "eth" -a "$interface" != "wlan" ]; then
  echo "Invalid interface '$3'"
  exit 4
fi

#Check the existence of uris_file
if [ $# -eq 5 ]; then
  if test ! -e $5; then
    echo "The uris_file '$5' not exist"
    exit 5
  fi
fi

#Define the partitions of the device
DEV=`basename $1`
DEVTYPE=echo ${DEV:0:2}
if [ $DEVTYPE=="sd" ]; then
  DEVICE=$1'1'
  DEVICE2=$1'2'
else
  DEVICE=$1'p1'
  DEVICE2=$1'p2'
fi

#Define display time of urls in seconds
DURATION=300

#Define of work directories
SCRIPTDIRECTORY=`dirname $0`
USERDIRECTORY=$PWD

cd $SCRIPTDIRECTORY

#Load network configure 
if test -e network-configure; then
  source network-configure
else
  echo "The network-configure file not exist, copy o rename 'network-configure.example' file as 'network-configure' and modify with good values"
  exit 6
fi

#Informative message
echo "The device '"`basename $1`"' is being prepared with the image '"`basename $2 .zip`"' and the following configuration:"
echo
echo " IP: $4"
echo
echo " SSH: enable"
echo
if [ $# -eq 5 ]; then
	echo " URLs:"
	for url in $(cat $5); do
		echo "   - $url"
	done
	echo
	echo " Display time: $DURATION seconds"
	echo
fi

#Copy the image to the device
gzip -d -c $2 | dd of=$1 status=progress

#Delay 2 second the command 'mount' for detect the partitions
sleep 2

#Enable ssh
mount $DEVICE /tmp
touch /tmp/ssh
umount /tmp

#Configure the network interface with static ip
mount $DEVICE2 /tmp

if [ "$interface" = "eth" ]; then
  echo "auto $3" >> /tmp/etc/network/interfaces
  echo "iface $3 inet static" >> /tmp/etc/network/interfaces
else
  echo "allow-hotplug $3" >> /tmp/etc/network/interfaces
  echo "auto $3" >> /tmp/etc/network/interfaces
  echo "iface $3 inet static" >> /tmp/etc/network/interfaces
  echo "   wpa-ssid $SSID" >> /tmp/etc/network/interfaces
  echo "   wpa-psk $PSK" >> /tmp/etc/network/interfaces
fi

echo "   address $4" >> /tmp/etc/network/interfaces
echo "   netmask $NETMASK" >> /tmp/etc/network/interfaces
echo "   gateway $GATEWAY" >> /tmp/etc/network/interfaces
echo "   dns-nameservers $DNS" >> /tmp/etc/network/interfaces

#Add uris to the Screenly database
ORDER=0
#Remove the default uris from the Screenly database
sqlite3 /tmp/home/pi/.screenly/screenly.db << EOF
	DELETE FROM assets
EOF
#Add uris to the Screenly database from the file
if [ $# -eq 5 ]; then
  for URI in $(cat $5); do 
    sqlite3 /tmp/home/pi/.screenly/screenly.db << EOF
      INSERT INTO assets (asset_id, name, uri, start_date, end_date, duration, mimetype, is_enabled, play_order, skip_asset_check) VALUES ("$ORDER", "$URI", "$URI", datetime('now'), '9999-12-28 23:59:00', $DURATION, 'webpage', 1, $ORDER, 1);
EOF
    ORDER=`expr $ORDER + 1`
  done
#Add urls to the Screenly database from the terminal
else
	read -p "What url do you want to show? (empty to finish)" URI 
	until [ "$URI" == "" ]; do
		sqlite3 /tmp/home/pi/.screenly/screenly.db << EOF
      		INSERT INTO assets (asset_id, name, uri, start_date, end_date, duration, mimetype, is_enabled, play_order, skip_asset_check) VALUES ("$ORDER", "$URI", "$URI", datetime('now'), '9999-12-28 23:59:00', $DURATION, 'webpage', 1, $ORDER, 1);
EOF
    	ORDER=`expr $ORDER + 1`
    	read -p "What other url do you want to show? (empty to finish)" URI
	done
fi

#Enable the use of mouse and keyboard
cat /tmp/home/pi/.config/uzbl/config-screenly > /tmp/home/pi/.config/uzbl/config-screenly.backup
cat config/config-uzbl > /tmp/home/pi/.config/uzbl/config-screenly
cd $USERDIRECTORY

umount /tmp

#Calculate the total time needed
END=$(date +%s)
DIFF=$(( $END - $START ))
echo
echo "This process took $DIFF seconds"
