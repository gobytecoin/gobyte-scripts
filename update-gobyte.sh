#!/bin/bash

cd ~/
sudo gobyte-cli stop
sudo rm -fr gobyte/
sudo git clone https://github.com/gobytecoin/gobyte
cd gobyte
sudo ./autogen.sh
sudo ./configure --without-gui --disable-tests
sudo make
sudo make install
sudo gobyted
