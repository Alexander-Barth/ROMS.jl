# ROMS source code in ~/src/roms
# ~/Data/Bathymetry/combined_emodnet_bathymetry.nc
# ~/Data/Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc


BUILD_DIR="$HOME/ROMS-implementation-test"

mkdir -p ~/src/
cd ~/src/
svn checkout --no-auth-cache --non-interactive  --username "$ROMS_USERNAME" \
    --password "$ROMS_PASSWORD" https://www.myroms.org/svn/src/tags/roms-3.9 roms
cd ~/src/roms
echo svnversion $(svnversion)

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

wget -O liguriansea.h 'https://dox.ulg.ac.be/index.php/s/9yqxI4tp5hNr2Sg/download'

# get compile script
cp ~/src/roms/ROMS/Bin/build_roms.sh build_roms.sh

patch build_roms.sh <<EOF
105c105
< export   ROMS_APPLICATION=UPWELLING
---
> export   ROMS_APPLICATION=LigurianSea
110c110
< export        MY_ROOT_DIR=\${HOME}/ocean/repository
---
> export        MY_ROOT_DIR=\${HOME}
123c123
<  export       MY_ROMS_SRC=\${MY_ROOT_DIR}/trunk
---
>  export       MY_ROMS_SRC=\${MY_ROOT_DIR}/src/roms
171,172c171,172
<  export              FORT=ifort
< #export              FORT=gfortran
---
> #export              FORT=ifort
> export              FORT=gfortran
177c177
< #export       USE_NETCDF4=on            # compile with NetCDF-4 library
---
>  export       USE_NETCDF4=on            # compile with NetCDF-4 library
EOF

if [ -e build_roms.sh.rej ]; then
    cat build_roms.sh.rej
fi

# Compile ROMS
./build_roms.sh -j 2 -noclean

