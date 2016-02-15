#!/usr/bin/env bash

set -x

# Install some additional drivers, including support for FTDI dongles
# http://askubuntu.com/questions/541443/how-to-install-usbserial-and-ftdi-sio-modules-to-14-04-trusty-vagrant-box
sudo apt-get update -qq
sudo apt-get install -y linux-image-extra-virtual
sudo modprobe ftdi_sio vendor=0x0403 product=0x6001

# Install FTDI lib
# cd /home/vagrant
# wget -nv http://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-x86_64-1.3.6.tgz
# tar xvf libftd2xx-x86_64-1.3.6.tgz
# cd release/build
# cp -r lib* /usr/local/lib
# chmod 0755 /usr/local/lib/libftd2xx.so.1.3.6
# ln -sf /usr/local/lib/libftd2xx.so.1.3.6 /usr/local/lib/libftd2xx.so
# cd /home/vagrant
# rm -rf release
# rm *.tgz

# Install basic development tools
sudo dpkg --add-architecture i386
sudo apt-get update -qq
sudo apt-get install -y build-essential autotools-dev autoconf pkg-config libusb-1.0-0 libusb-1.0-0-dev libftdi1 libftdi-dev git libc6:i386 libncurses5:i386 libstdc++6:i386 cowsay figlet language-pack-en
sudo locale-gen UTF-8

# Install python
sudo apt-get install -y python2.7 python-numpy python-scipy python-matplotlib

# Install development tools for avr
sudo apt-get install -y gcc-avr binutils-avr avr-libc avrdude

# The makefile from Mutable Instruments expects the avr-gcc binaries to be
# in a different directory.
sudo ln -s /usr /usr/local/CrossPack-AVR

# Install openocd
cd /home/vagrant
wget -nv http://downloads.sourceforge.net/project/openocd/openocd/0.9.0/openocd-0.9.0.tar.gz
tar xvfz openocd-0.9.0.tar.gz
cd openocd-0.9.0
./configure --enable-ftdi --enable-legacy-ft2232-libftdi --enable-stlink
make
sudo make install
cd /home/vagrant
rm -rf openocd-0.9.0
rm *.tar.gz

# Install stlink
cd /home/vagrant
wget https://github.com/texane/stlink/archive/1.1.0.tar.gz
tar xvfz 1.1.0.tar.gz
cd stlink-1.1.0
./autogen.sh
./configure
make
sudo make install
sudo cp 49-stlink*.rules /etc/udev/rules.d/
cd /home/vagrant
rm -rf stlink-1.1.0
rm *.tar.gz

# Allow non-root users to access USB devices such as Atmel AVR and Olimex
# programmers, FTDI dongles...
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="0003", GROUP="users", MODE="0666"' >> /etc/udev/rules.d/60-programmers.rules
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002a", GROUP="users", MODE="0666"' >> /etc/udev/rules.d/60-programmers.rules
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002b", GROUP="users", MODE="0666"' >> /etc/udev/rules.d/60-programmers.rules
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2104", GROUP="users", MODE="0666"' >> /etc/udev/rules.d/60-programmers.rules
echo 'SUBSYSTEMS=="usb", KERNEL=="ttyUSB*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", GROUP="users", MODE="0666", SYMLINK+="ftdi-usbserial"' >> /etc/udev/rules.d/60-programmers.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Install toolchain for STM32F4
cd /home/vagrant
wget -nv https://launchpad.net/gcc-arm-embedded/4.8/4.8-2013-q4-major/+download/gcc-arm-none-eabi-4_8-2013q4-20131204-linux.tar.bz2
tar xjf gcc-arm-none-eabi-4_8-2013q4-20131204-linux.tar.bz2
sudo mv gcc-arm-none-eabi-4_8-2013q4 /usr/local/arm-4.8.3/
rm *.tar.bz2
# (We're progressively checking that all STM32F1 projects can also be built with
# this gcc version instead of 4.5.2).
ln -s /usr/local/arm-4.8.3 /usr/local/arm

# Code is stored in the VM itself
# CODE_DIRECTORY=/home/vagrant
# Code is stored in a directory shared between the VM and the host.
CODE_DIRECTORY=/vagrant

# Get modules source code
cd $CODE_DIRECTORY
USER_GITHUB_URL=$1
if [ $USER_GITHUB_URL ]
then
  # Get from a clone of the original repo.
  sudo -s -u vagrant -H git clone $USER_GITHUB_URL eurorack-modules
  cd $CODE_DIRECTORY/eurorack-modules
  sudo -s -u vagrant -H git remote add pichenettes https://github.com/pichenettes/eurorack.git
else
  # Get from the original repo.
  sudo -s -u vagrant -H git clone https://github.com/pichenettes/eurorack.git eurorack-modules
  cd $CODE_DIRECTORY/eurorack-modules
fi
sudo -s -u vagrant -H git submodule init
sudo -s -u vagrant -H git submodule update

# Add . to PYTHONPATH
echo 'export LC_ALL=en_US.UTF-8' >> /home/vagrant/.bashrc
echo 'export LANGUAGE=en_US' >> /home/vagrant/.bashrc
echo 'export PYTHONPATH=.:$PYTHONPATH' >> /home/vagrant/.bashrc
echo "cd $CODE_DIRECTORY/eurorack-modules" >> /home/vagrant/.bashrc
