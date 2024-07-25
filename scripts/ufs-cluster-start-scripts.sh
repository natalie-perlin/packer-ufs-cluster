#!/bin/bash
mkdir -p /opt/build 
mkdir -p /opt/dist
apt-get update 
apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl 
rm -rf /var/lib/apt/lists/*
# install cmake
cd /opt/build 
curl -LO https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-x86_64.sh && /bin/bash cmake-3.23.1-linux-x86_64.sh --prefix=/usr/local --skip-license
apt-get update -yq --allow-unauthenticated
apt-get install -y lmod 
apt-get install -y tzdata 
ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime 
dpkg-reconfigure --frontend noninteractive tzdata 
apt-get -y install build-essential git vim python3 wget libexpat1-dev lmod bc time 
apt-get install -yq libtiff-dev git-lfs python3-distutils python3-pip wget m4 unzip curl
apt-get install -y --no-install-recommends apt-utils
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
ls -l /bin/sh
mkdir -p /opt
cd /opt
git clone -b feature/oneapi --recursive https://github.com/NOAA-EPIC/spack-stack.git
cd /opt/spack-stack
pwd
ls -l /bin/sh
sed -i 's/source/./g' ./setup.sh
. ./setup.sh
spack install intel-oneapi-compilers 
ls -l /bin/sh  
pwd 
ls -l 
. ./setup.sh 
spack install intel-oneapi-compilers 
spack install intel-oneapi-mpi && spack compiler list && spack find 
spack compiler add `spack location -i intel-oneapi-compilers`/compiler/latest/linux/bin/intel64 && spack compiler list 
spack compiler rm gcc@9.4.0
ENV PATH="${PATH}:/usr/local"
#this module.yaml file sets the format for tcl modules built by spack to have no extra hashes
wget -O /tmp/modules.yaml https://noaa-epic-dev-pcluster.s3.amazonaws.com/scripts/modules.yml
cp /tmp/modules.yaml /opt/spack-stack/spack/etc/spack/defaults
#Add the intel compiler to spack and find externals, then install any general packages (cmake) that don't need to be 
#part of the concretization
. ./setup.sh 
spack compiler add 
spack external find wget 
spack external find m4 
spack external find git 
spack external find curl 
spack external find git-lfs 
spack external find openssl 
spack external find libjpeg-turbo 
spack external find perl 
spack external find python 
spack install zlib@1.2.12 
spack install cmake@3.22.1 
spack install curl@7.49.1 
spack module tcl refresh -y --delete-tree && source /usr/share/lmod/lmod/init/bash && module avail
#set up modules to be loaded automatically when shelling into the container
. ./setup.sh
echo "source /usr/share/lmod/lmod/init/bash" >> /root/.bashenv
echo "module use module use /opt/spack-stack/spack/share/spack/modules/linux-*" >> /root/.bashenv
echo "module load cmake/3.22.1 intel-oneapi-compilers/2022.1.0 intel-oneapi-mpi/2021.6.0 " >> /root/.bashenv
echo "[[ -s ~/.bashenv ]] && source ~/.bashenv" >> /root/.bash_profile
echo "[[ -s ~/.bashenv ]] && source ~/.bashenv" >> /root/.bashrc

###install go###
cd /lustre
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
tar -xvf go1.21.6.linux-amd64.tar.gz
cd go
export PATH=$PATH:/lustre/go/bin
export GOPATH=/lustre/go
export GOBIN=/lustre/go/bin

###Install singularity###
cd /lustre
wget https://github.com/sylabs/singularity/releases/download/v3.11.0/singularity-ce-3.11.0.tar.gz
tar -xzf singularity-ce-3.11.0.tar.gz
cd singularity-ce-3.11.0/
#sudo yum install libseccomp-dev
sudo yum update
sudo yum install libglib2.0-dev
./mconfig &&     make -C ./builddir &&     sudo make -C ./builddir install

###Upgrade lmod/Lua###
cd /home/ubuntu
sudo apt install lua5.3
sudo apt remove lua5.2
wget https://sourceforge.net/projects/lmod/files/Lmod-8.6.tar.bz2
tar xvfj Lmod-8.6.tar.bz2
cd Lmod-8.6
./configure --prefix=/opt/apps
sudo make install
source /opt/apps/lmod/lmod/init/bash

###Install ruby and ruby-dev###
cd /home/ubuntu
sudo apt-get install ruby
sudo apt-get install ruby-dev

###Install rocoto###
cd /home/ubuntu
PREFIX="/home/ubuntu/rocoto"
mkdir -p $PREFIX && cd $PREFIX
git clone -b 1.3.7 https://github.com/christopherwharrop/rocoto.git 1.3.7
cd 1.3.7
./INSTALL 2>&1 | tee rocoto-1.3.7.install.log
# Prepare a modulefile for rocoto
cd $PREFIX
export ROCOTOBIN=$PREFIX/1.3.7/bin
export ROCOTOLIB=$PREFIX/1.3.7/lib
mkdir $PREFIX/modulefiles
mkdir $PREFIX/modulefiles/rocoto
touch $PREFIX/modulefiles/rocoto/1.3.7.lua
cat > modulefiles/rocoto/1.3.7.lua << EOF
help([[
  Set environment variables for rocoto workflow manager)
]])

-- Make sure another version of the same package is not already loaded
conflict("rocoto")

-- Set environment variables
prepend_path("PATH","$ROCOTOBIN")
prepend_path("LD_LIBRARY_PATH","$ROCOTOLIB")
EOF
#
# Pre-build a singularity container with spack-stack v1.6.0
cd /home/ubuntu
sudo -u ubuntu singularity build /home/ubuntu/ubuntu22.04-intel-srw-ss-v1.6.0.img docker://noaaepic/ubuntu22.04-intel-srw:ss-v1.6.0
#
