#!/bin/bash

# ----------------------------------------------------------------------
# Description:      Pinguino IDE Install Script for Linux
# Author:           regis blanchot <rblanchot@gmail.com>
# ----------------------------------------------------------------------
# TODO
# ----------------------------------------------------------------------
# xx-xx-201x : v1.4.0 added python 3 support
# replace package installation with git clone ?
# replace package update with git pull ?
# replace sdcc package with the official sdcc archive ?
# ----------------------------------------------------------------------
# CHANGELOG
# ----------------------------------------------------------------------
# 12-03-2018 : v1.3.3 updated pyusb 0.x to 1.x (to support core functions)
# 28-09-2017 : v1.3.2 added cmake installation
# 11-04-2017 : v1.3.1 fixed installation path
# 20-03-2017 : v1.3.0 added python module upgrade with pip
# 13-03-2017 : v1.2.3 fixed XC8 version in pinguino.conf
# 31-12-2016 : v1.2.2 added pinguino.conf updating
# 05-10-2016 : v1.2.1 changed installations order : compilers first
# 11-08-2016 : v1.2.0 added pinguino.linux.conf updating
# 11-08-2016 : v1.1.3 added latest XC8 version downloading
# 11-08-2016 : v1.1.2 fixed XC8 installation by removing "/dev/null" direction 
# 11-08-2016 : v1.1.1 added post-install procedure for the testing version
# 03-04-2016 : v1.1.0 changed dpkg for gdebi
# 09-05-2016 : v1.0.3 added "--mode text" option to XC8 installer
# 11-05-2016 : v1.0.2 added update option to run git
# 31-03-2016 : v1.0.1 removed wget "--show-progress" option (not supported on all Linux distro)
# 25-04-2014 : v1.0.0 first release    
# ----------------------------------------------------------------------

VERSION="1.3.3"

DOWNLOAD=1
UPGRADE=1
INSTALL=1
INTERFACE=
RELEASE=1

STABLE=11
TESTING=12
DPKG=gdebi

#XC8INST=xc8-v1.44-full-install-linux-installer.run
XC8INST=mplabxc8linux

# XC8 compiler location
XC8DIR=http://www.microchip.com
#XC8DIR=http://ww1.microchip.com
# Pinguino Sourceforge location
DLDIR=https://sourceforge.net/projects/pinguinoide/files/linux
#DLDIR=downloads.sourceforge.net/projects/pinguinoide/files/linux
# Pinguino 
location
PDIR=/opt/pinguino

# Compilers code
NONE=0
SDCC=1
XC8=2
GCC=4

# ANSI Escape Sequences
RED='\e[31;1m'
BLINK='\e[5;1m'
GREEN='\e[32;1m'
YELLOW='\e[33;1m'
TERM='\e[0m'
CLS='\e[2J'

WARNING=${YELLOW}
ERROR=${RED}
NORMAL=${GREEN}
END=${TERM}

# Log a message out to the console
function log
{
    echo -e $1"$*"$TERM
}

# Download a package if newer
function fetch
{
    log $NORMAL "* $1 package"
    if [ "$1" == "${XC8INST}" ]; then
        wget ${XC8DIR}/$1 --quiet --timestamping --progress=bar:force
    else
        wget ${DLDIR}/$1 --quiet --timestamping --progress=bar:force
    fi
}

# Install a package if newer
function install
{
    log $NORMAL "* $1 package"
    filename=$1
    extension="${filename##*.}"
    if [ "${extension}" == "deb" ]; then
        sudo gdebi --non-interactive --quiet $1 > /dev/null
        #sudo dpkg --install --force-overwrite $1 > /dev/null
        #sudo apt-get install -f > /dev/null
    else
        sudo chmod +x ${XC8INST}
        NEWXC8VER=v1.$(sudo ./${XC8INST} --version | grep -Po '(?<=v1.)\d\d')
        #log $ERROR ${XC8VER}
        if [ ! -d "/opt/microchip/xc8/$NEWXC8VER" ]; then
            sudo ./${XC8INST} --mode text
        fi
    fi
}

# TITLE
########################################################################

log $CLS
log $NORMAL ------------------------------------------------------------
log $NORMAL Pinguino IDE Installation Script v${VERSION}
log $NORMAL Regis Blanchot - rblanchot@pinguino.cc
log $NORMAL ------------------------------------------------------------

# DO WE RUN AS ADMIN ?
########################################################################

user=`env | grep '^USER=' | sed 's/^USER=//'`
if [ "$user" == "root" -a "$UID" == "0" ]; then
    log $ERROR "Don't run the installer as Root or Super User."
    log $ERROR "Admin's password will be asked later."
    log $ERROR "Usage : ./installer.sh"
    echo -e "\r\n"
    exit 1
fi

# DO WE HAVE WGET ?
########################################################################

if [ ! -e "/usr/bin/wget" ]; then
    log $WARNING "Wget not found, installing it ..."
    sudo apt-get install wget
fi

# DO WE HAVE GDEBI ?
########################################################################

if [ ! -e "/usr/bin/gdebi" ]; then
    log $WARNING "Gdebi not found, installing it ..."
    sudo apt-get install gdebi
fi

# DO WE HAVE GIT ?
########################################################################

if [ ! -e "/usr/bin/git" ]; then
    log $WARNING "Git not found, installing it ..."
    sudo apt-get install git
fi

# DO WE HAVE PIP ?
########################################################################

if [ ! -e "/usr/bin/pip" ]; then
    log $WARNING "Pip not found, installing it ..."
    sudo apt-get install python-pip python-pyside
fi

# DO WE HAVE QTMAKE and CMAKE ?
########################################################################

if [ ${UPGRADE} ]; then

    if [ ! -e "/usr/bin/qmake-qt4" ]; then
        log $WARNING "Qmake not found, installing it ..."
        sudo apt-get install qt4-default qt4-qmake cmake
    fi

fi

# ARCHITECTURE
########################################################################

UNAME=`uname -m`

if [ ${UNAME} == "armv6l" ]; then
    ARCH=RPi
    log $NORMAL "Host is a Raspberry Pi."
elif [ ${UNAME} == "armv7l" ]; then
    ARCH=RPi
    log $NORMAL "Host is a Raspberry Pi 2."
elif [ ${UNAME} == "x86_64" ]; then
    ARCH=64
    log $NORMAL "Host is a ${ARCH}-bit GNU/Linux."
else
    ARCH=32
    log $NORMAL "Host is a ${ARCH}-bit GNU/Linux."
fi

# RELEASE
########################################################################

if [ ${RELEASE} ]; then

    log $NORMAL "Which release of Pinguino do you want to update/install ?"
    log $ERROR "The testing version is now recommended."
    log $WARNING "1) Stable"
    log $WARNING "2) Testing (default)"

    echo -e -n "\e[31;1m >\e[05m"
    read what
    echo -e -n "\e[00m"

    case $what in
        1) REL=stable ;;
        *) REL=testing  ;;
    esac

else

    REL=stable

fi

if [ ${REL} == "testing" ]; then
    RELEASE=${TESTING}
else
    RELEASE=${STABLE}
fi

mkdir -p ${REL}
cd ${REL}

# DOWNLOAD
########################################################################

if [ ${DOWNLOAD} ]; then

    if [ $ARCH == RPi ]; then

        log $NORMAL "Host memory is too limited for 32-bit compiler."
        log $NORMAL "Do you want to install the 8-bit compiler ?"
        log $WARNING "1) no (default)"
        log $WARNING "2) yes"

    else

        if [ "${REL}" == "stable" ]; then

            log $NORMAL "Which compiler(s) do you want to install ?"
            log $WARNING "1) none of them (default)"
            log $WARNING "2) SDCC (PIC18F) only"
            log $WARNING "3) GCC (PIC32MX) only"
            log $WARNING "4) both (SDCC and GCC)"

        else

            log $NORMAL "Which compiler(s) do you want to install ?"
            log $WARNING "1) none of them (default)"
            log $WARNING "2) SDCC (PIC18F) only"
            log $WARNING "3) XC8 (PIC16F and PIC18F) only"
            log $WARNING "4) GCC (PIC32MX) only"
            log $WARNING "5) SDCC and XC8 (PIC16F and PIC18F) only"
            log $WARNING "6) all (SDCC, XC8 and GCC)"

        fi

    fi

    echo -e -n "\e[31;1m >\e[05m"
    read what
    echo -e -n "\e[00m"

    if [ "${REL}" == "stable" ]; then

        case $what in
            2)  COMP=$SDCC ;;
            3)  COMP=$GCC ;;
            4)  COMP=$((SDCC|GCC)) ;;
            *)  COMP=$NONE ;;
        esac

    else

        case $what in
            2)  COMP=$SDCC ;;
            3)  COMP=$XC8 ;;
            4)  COMP=$GCC ;;
            5)  COMP=$((SDCC|XC8)) ;;
            6)  COMP=$((SDCC|XC8|GCC)) ;;
            *)  COMP=$NONE ;;
        esac

    fi

fi

########################################################################

if [ ${INTERFACE} ]; then

    log $NORMAL "Which graphic interface do you want to install ?"
    log $WARNING "1) Tkinter-based IDE (simple and light)"
    log $WARNING "2) Qt4-based IDE (default, recommended)"
    read what

    case $what in
        1) TK=YES ;;
        *) TK=NO  ;;
    esac

else

    TK=NO

fi

########################################################################

if [ ${DOWNLOAD} ]; then

    log $WARNING "Downloading packages (please be patient) ..."

    #i=0

    # Pinguino files
    
    if [ $TK == YES ]; then
        fetch ${REL}/pinguino-ide-tk.deb
    else
        fetch ${REL}/pinguino-ide.deb
    fi
    
    fetch ${REL}/pinguino-libraries.deb

    # Compilers

    #cd ..
    case 1 in
        $(( (COMP & SDCC) >0 )) ) fetch pinguino-linux${ARCH}-sdcc-mpic16.deb;;&
        $(( (COMP &  XC8) >0 )) ) fetch ${XC8INST};;&
        $(( (COMP &  GCC) >0 )) ) fetch pinguino-linux${ARCH}-gcc-mips-elf.deb;;&
    esac
    #cd ${REL}

fi

# INSTALL
########################################################################

if [ ${INSTALL} ]; then

    log $WARNING "Installing packages ..."

    #i=0

    # Compilers (must be installed first)

    #cd ..
    case 1 in
        $(( (COMP & SDCC) >0 )) ) install pinguino-linux${ARCH}-sdcc-mpic16.deb;;&
        $(( (COMP &  XC8) >0 )) ) install ${XC8INST};;&
        $(( (COMP &  GCC) >0 )) ) install pinguino-linux${ARCH}-gcc-mips-elf.deb;;&
    esac
    #1
    #cd ${REL}

    # Pinguino files
    
    if [ $TK == YES ]; then
        install pinguino-ide-tk.deb
    else
        install pinguino-ide.deb
    fi

    install pinguino-libraries.deb

fi

# COMPILERS LIST
########################################################################

log $WARNING "Checking compilers ..."

#XC8
CURXC8VER="v0.00"
for XC8VER in $(ls /opt/microchip/xc8); do
    if [ "${XC8VER}" > "${CURXC8VER}" ]; then
        CURXC8VER=${XC8VER} 
    fi
done
if [ "${CURXC8VER}" != "v0.00" ]; then
    log $NORMAL XC8 ${CURXC8VER} has been found on this computer.
else
    log $ERROR No XC8 compiler found on this computer.
fi

#SDCC
if [ -e "/opt/pinguino/p8/bin/sdcc" ]; then
    log $NORMAL SDCC has been found on this computer :
    log $NORMAL $(/opt/pinguino/p8/bin/sdcc --version)
else
    log $ERROR No SDCC compiler found on this computer.
fi

#P32-GCC
if [ -e "/opt/pinguino/p32/bin/p32-gcc" ]; then
    log $NORMAL P32-GCC has been found on this computer :
    log $NORMAL $(/opt/pinguino/p32/bin/p32-gcc --version)
else
    log $ERROR No P32-GCC compiler found on this computer.
fi

# UPGRADE PYTHON MODULES
########################################################################

if [ ${UPGRADE} ]; then

    log $WARNING "Upgrading Python modules ..."
    log $ERROR "Please be patient, it can be quite long the first time."

    #sudo python -m pip install --upgrade pip pyside pyusb wheel beautifulsoup4 setuptools requests

    # Get the latest version of pip
    sudo python -m pip install --upgrade pip

    # Updating pyside doesn't work
    #sudo python -m pip install --upgrade pyside

    # Update pyusb 0.x to 1.x (to support core functions)
    sudo python -m pip install --pre pyusb

    sudo python -m pip install --upgrade wheel
    sudo python -m pip install --upgrade beautifulsoup4
    sudo python -m pip install --upgrade setuptools
    sudo python -m pip install --upgrade requests

fi

# UPDATE LINUX CONFIG FILES
########################################################################

HOME=$(echo ~)
PCONF=/opt/pinguino/v${TESTING}/pinguino/qtgui/config/pinguino.linux.conf
#PCONF=${HOME}/Pinguino/v${RELEASE}/pinguino.conf
rm -f ${PCONF} > /dev/null 2>&1
touch ${PCONF}
echo -e "[Paths]" >> ${PCONF}
echo -e "sdcc_bin = /opt/pinguino/p8/bin" >> ${PCONF}
echo -e "gcc_bin  = /opt/pinguino/p32/bin" >> ${PCONF}
if [ "${REL}" == "testing" ]; then
echo -e "xc8_bin  = /opt/microchip/xc8/${CURXC8VER}/bin" >> ${PCONF}
fi
echo -e "pinguino_8_libs  = /opt/pinguino/v${RELEASE}/p8" >> ${PCONF}
echo -e "pinguino_32_libs = /opt/pinguino/v${RELEASE}/p32" >> ${PCONF}
echo -e "user_libs = /opt/pinguino/v${RELEASE}/pinguinolibs" >> ${PCONF}
echo -e "install_path = /opt/pinguino/v${RELEASE}" >> ${PCONF}
#echo -e "install_path = ${HOME}/Pinguino/v${RELEASE}" >> ${PCONF}
echo -e "user_path = ${HOME}/Pinguino/v${RELEASE}" >> ${PCONF}

# POSTINSTALL
########################################################################

log $WARNING "Copying files to your Pinguino folder ..."

if [ "${REL}" == "stable" ]; then
    python /opt/pinguino/v${STABLE}/post_install.py > /dev/null 2>&1
else
    cd /opt/pinguino/v${TESTING}
    mkdir -p ${HOME}/Pinguino/v${TESTING}
    cp -R examples graphical_examples source ${HOME}/Pinguino/v${TESTING}/
    #python /opt/pinguino/v${TESTING}/pinguino/pinguino_reset.py
    # > /dev/null 2>&1
    #python /opt/pinguino/v${TESTING}/cmd/pinguino-reset.py
fi

# LAUNCH
########################################################################

log $WARNING "Do you want to launch the IDE ?"
log $NORMAL "1) Yes (default)"
log $NORMAL "2) No"

echo -e -n "\e[31;1m >\e[05m"
read what
echo -e -n "\e[00m"

case $what in
    2)  log $NORMAL "Installation complete." ;;

    *)  if [ "${REL}" == "stable" ]; then
            python /opt/pinguino/v${STABLE}/pinguino.py
        else
            python /opt/pinguino/v${TESTING}/pinguino-ide.py
        fi
        ;;
esac
