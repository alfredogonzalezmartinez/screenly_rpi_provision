# Raspberry provision with Screenly

This script allows you to provision a Raspberry with a Screenly image, configure the network, enable the SSH connection, add the URLs you want to see and enables the use of mouse and keyboard.

It is necessary to pass the following parameters "disk_device", "base_image", "network_interface" and "ip". Optionally we can pass a fifth parameter "urls_file" to add the URLs. If we don't pass this last parameter, we will ask for the urls by in the terminal.

**disk_device**

Complete path of the disk device (SD card). Can use the comand "sudo fdisk -l" to identify it. Example: /dev/mmcblk0

**base_image**

Complete path of the Screenly image. Can get the Screenly image in the [official repository](https://github.com/screenly/screenly-ose/releases). Example: ~/downloads/image_2018-11-23-Screenly-OSE-lite.zip

**network_interface**

Name of network interface. "eth0" for cable conection or "wlan0" for Wi-Fi conection.

**ip**

Assigned ip address. Example: 10.100.64.22

**urls_file**

Optional parameter. Complete path of the file that contains the URLs, one per line. Example: ~/URLs.txt

## Execution

The script needs to run with superuser privileges, so it must be run with the command "sudo".
```
sudo ./rpi_provision.sh disk_device base_image network_interface ip [urls_file]
```
Example:
```
 sudo ./rpi_provision.sh /dev/mmcblk0 ~/downloads/image_2018-11-23-Screenly-OSE-lite.zip wlan0 10.100.64.22 ~/URLs.txt
```

## How to use?

1. Copy or rename the file "network-configure.example" as "network-configure" and modify whit your network configutation.
2. [Download the Screenly image from the official repository](https://github.com/screenly/screenly-ose/releases)
3. (Optional) Create a file with the URLs that you want to show.
4. Insert the microSD in the computer and localice the device. You can use "sudo fdisk -l" to identify the device path.
5. Execute the scritp. 
    Example:
    ```
     sudo ./rpi_provision.sh /dev/mmcblk0 ~/downloads/image_2018-11-23-Screenly-OSE-lite.zip wlan0 10.100.64.22 ~/URLs.txt
    ```
