# Vagrant environment for Mutable Instruments modules hacking

This configuration file and this shellscript create a Linux (ubuntu) virtual machine configured with all the right tools for compiling and installing the firmware of Mutable Instruments' modules.

## Kudos and inspiration

* Adafruit's [ARM Toolchain for Vagrant](https://github.com/adafruit/ARM-toolchain-vagrant)
* Novation's [LaunchPad pro](https://github.com/dvhdr/launchpad-pro)

## Requirements

* [VirtualBox 5.x](https://www.virtualbox.org/wiki/Downloads)
* [VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)

The Extension pack consists of a file with the `vbox-extpack` extension.  On windows, double click on it.  On OS X or Linux, the file needs to be installed from the command line with the command:

    VBoxManage extpack install <filename>

Finally if you are running a Linux operating system you will want to add your user to the `vboxusers` group so that the virtual machine can access your USB devices.  Run the following command:

    sudo usermod -a -G vboxusers $USER

Then **log out and log back in** to make sure the group change takes effect.

## Usage

To start the VM, open a terminal in the directory with the Vagrantfile and run:

    vagrant up

The first time the VM is started, all tools will be downloaded, and the latest version of the code will be grabbed from github.  The process takes about 15 minutes, depending on the speed of your internet connection or computer.

Then, you can log onto the virtual machine by running:

    vagrant ssh

Once in the virtual machine, you can try, for example, to compile Clouds' bootloader and code:

    make -f clouds/bootloader/makefile hex
    make -f clouds/makefile

To write the firmware to the module with an Olimex ARM-USB-OCD-H JTAG adapter, use:

    make -f clouds/makefile upload

Using other programmers is of course possible, please see [Customization](#customization).

Or you can generate a .wav file for the built-in audio updater:

    make -f clouds/makefile wav

The firmware update file will be put in `build/clouds/clouds.wav`.

Once you're done with your hacking session, you can leave the VM terminal with:

    exit

The virtual machine continues running and can be reaccessed with `vagrant ssh`. It can also be suspended with `vagrant suspend`, halted with `vagrant halt`, and completely destroyed with `vagrant destroy`.  Note that with this last command, you might lose any files you have created inside the VM's disk image!

## Moving files between the VM and the host

By default, the working directory (`eurorack-modules`) is installed in the `/vagrant` directory, which is shared between the VM and the host.  You can thus use any text editor on the host to modify the files.  Note that any file can be transferred between the VM and the host by being copied in this location.

If you prefer working in a more self-contained environment and leave your host directory clean, you can comment the line `CODE_DIRECTORY=/vagrant` and uncomment the line `CODE_DIRECTORY=/home/vagrant` before setting up the VM.  The code will not be installed in the shared directory, and will be accessible only from within the VM.

## USB issues

To pass through USB devices from your real machine to the virtual machine, consult the [VirtualBox USB documentation](https://www.virtualbox.org/manual/ch03.html#idp96037808).

## <a name=#customization></a>Customization

### Using a different programmer
To use a programmer other than the default (AVR ISP mkII, ARM-USB-OCD-H) it is no longer necessary to edit the makefiles. Instead, the programmer can be set in the shell for the current session, e.g.

	export PGM_INTERFACE=stlink-v2
	export PGM_INTERFACE_TYPE=hla

for ARM projects using a JTAG adapter. Similarly for AVR projects, you can use

	export PROGRAMMER=stk500
	export PROGRAMMER_PORT=/dev/tty.usbserial-xxxxxxxx

Any further calls to `make` will then automatically use these settings. To make them permanent, add the exports to the end of `~/.bashrc`.

See [stmlib/makefile.inc](https://github.com/pichenettes/stmlib/blob/master/makefile.inc#L29) and [avrlib/makefile.mk](https://github.com/pichenettes/avril/blob/master/makefile.mk#L16) for more options that can be customized.

Another way (e.g. to test if settings are correct) is to just specify the value in the call to `make`:

	PGM_INTERFACE=arm-usb-tiny-h make -f braids/makefile upload

### Custom repository URL
If you want to build code from your own github fork, you can specify the repository to clone when you create the VM via the `USER_GITHUB_URL` environment variable, e.g.

	USER_GITHUB_URL=https://github.com/<username>/eurorack.git vagrant up

The Mutable Instruments' repository is automatically added as the git remote `pichenettes`.