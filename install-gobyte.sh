#!/bin/sh
#Version 0.1.1
#Info: Installs GoByte daemon, Masternode based on privkey.
#GoByte Version 0.1.12.1 or above
#Tested OS: Ubuntu 17.04, 16.04, and 14.04
#TODO: make script less "ubuntu" or add other linux flavors
#TODO: remove dependency on sudo user account to run script (i.e. run as root and specifiy gobyte user so gobyte user does not require sudo privileges)
#TODO: add specific dependencies depending on build option (i.e. gui requires QT4)

noflags() {
    echo "=-=-=-=-=-=-=-=-=-=-="
    echo "Usage: install-gobyte"
    echo "Example: install-gobyte"
    echo "=-=-=-=-=-=-=-=-=-=-="
    exit 1
}

message() {
	echo "==============================>>>"
	echo "| $1"
	echo "==============================<<<"
}

error() {
	message "An error occured, you must fix it to continue!"
	exit 1
}


prepdependencies() { #TODO: add error detection
	message "Installing dependencies..."
	sudo apt-get update
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
	sudo apt-get install automake curl libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common python-software-properties g++ bsdmainutils libevent-dev -y
	sudo add-apt-repository ppa:bitcoin/bitcoin -y
	sudo apt-get update
	sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}

createswap() { #TODO: add error detection
	message "Creating 2GB temporary swap file...this may take a few minutes..."
	sudo dd if=/dev/zero of=/swapfile bs=1M count=2000
	sudo mkswap /swapfile
	sudo chown root:root /swapfile
	sudo chmod 0600 /swapfile
	sudo swapon /swapfile

	#make swap permanent
	sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
}

clonerepo() { #TODO: add error detection
	message "Cloning from github repository..."
  	cd ~/
	git clone https://github.com/gobytecoin/gobyte
}

compile() {
	cd gobyte #TODO: squash relative path
	message "Preparing to build..."
	./autogen.sh
	if [ $? -ne 0 ]; then error; fi
	message "Configuring build options..."
	./configure $1 --disable-tests
	if [ $? -ne 0 ]; then error; fi
	message "Building GoByte...this may take a few minutes..."
	make
	if [ $? -ne 0 ]; then error; fi
	message "Installing GoByte..."
	sudo make install
	if [ $? -ne 0 ]; then error; fi
}

createconf() {
	#TODO: Can check for flag and skip this
	#TODO: Random generate the user and password

	message "Creating gobyte.conf..."
	MNPRIVKEY="7dyTEWm6gdfb5XJXDRaCnX3iNU44waN1K7BY5KQh9wUDPwhuNG5"
	CONFDIR=~/.gobytecore
	CONFILE=$CONFDIR/gobyte.conf
	if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
	if [ $? -ne 0 ]; then error; fi

	mnip=$(curl -s https://api.ipify.org)
	rpcuser=$(date +%s | sha256sum | base64 | head -c 10 ; echo)
	rpcpass=$(openssl rand -base64 32)
	printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "rpcport=12454" "externalip=$mnip" "masternode=1" "masternodeprivkey=$MNPRIVKEY" > $CONFILE

        gobyted
        message "Wait 10 seconds for daemon to load..."
        sleep 20s
        MNPRIVKEY=$(gobyte-cli masternode genkey)
	gobyte-cli stop
	message "wait 10 seconds for deamon to stop..."
        sleep 10s
	sudo rm $CONFILE
	message "Updating gobyte.conf..."
        printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "rpcport=12454" "externalip=$mnip" "masternode=1" "masternodeprivkey=$MNPRIVKEY" > $CONFILE

}

success() {
	gobyted
	message "SUCCESS! Your gobyted has started. Masternode.conf setting below..."
	message "MN $mnip:12455 $MNPRIVKEY TXHASH INDEX"
	exit 0
}

install() {
	prepdependencies
	createswap
	clonerepo
	compile $1
	createconf
	success
}

#main
#default to --without-gui
install --without-gui
