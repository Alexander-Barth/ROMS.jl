#!/bin/bash
# ROMS source code in ~/src/roms
# ~/Data/Bathymetry/combined_emodnet_bathymetry.nc
# ~/Data/Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc


BUILD_DIR="$HOME/ROMS-implementation-test"

mkdir -p ~/src/
cd ~/src/

if [ ! -d roms ]; then

git config --global credential.helper '!f() { sleep 1; echo "username=${ROMS_USERNAME}"; echo "password=${ROMS_PASSWORD}"; }; f'


git clone https://github.com/myroms/roms
cd roms
git checkout roms-4.1

fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

wget -O liguriansea.h 'https://dox.ulg.ac.be/index.php/s/9yqxI4tp5hNr2Sg/download'

# get compile script
cp ~/src/roms/ROMS/Bin/build_roms.sh build_roms.sh

# "EOF" prevent subsituting variables like $HOME
patch build_roms.sh <<"EOF"
105c105
< export   ROMS_APPLICATION=UPWELLING
---
> export   ROMS_APPLICATION=LigurianSea
110c110
< export        MY_ROOT_DIR=${HOME}/ocean/repository
---
> export        MY_ROOT_DIR=${HOME}
124c124
<  export       MY_ROMS_SRC=${MY_ROOT_DIR}/svn/trunk
---
>  export       MY_ROMS_SRC=${MY_ROOT_DIR}/src/roms
173,174c173,174
<  export              FORT=ifort
< #export              FORT=gfortran
---
> #export              FORT=ifort
> export              FORT=gfortran
EOF

if [ -e build_roms.sh.rej ]; then
    cat build_roms.sh.rej
fi

# Compile ROMS
./build_roms.sh -j 2 -noclean
