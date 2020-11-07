# Get
# build_roms.sh.patch
# ROMS source code in ~/src/roms
# ~/Data/Bathymetry/combined_emodnet_bathymetry.nc
# ~/Data/Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc


BUILD_DIR="$HOME/Lectures/OCEA0036-1/ROMS-implementation-test"

mkdir -p ~/src/
cd ~/src/
svn checkout --username "$ROMS_USERNAME" --password "$ROMS_PASSWORD" https://www.myroms.org/svn/src/trunk roms
svn up -r1042

cd "$BUILD_DIR"

wget -O liguriansea.h 'https://dox.ulg.ac.be/index.php/s/9yqxI4tp5hNr2Sg/download'
wget -O build_roms.sh.patch 'https://dox.ulg.ac.be/index.php/s/9cha2VbR3DYvZHd/download'

# get compile script
cp ~/src/roms/ROMS/Bin/build_roms.sh build_roms.sh

# modify compile script
patch < build_roms.sh.patch

# Compile ROMS
./build_roms.sh -j 2 -noclean

# run julia script
julia --eval 'using ROMS; include(joinpath(dirname(pathof(ROMS)),"..","examples","example_config.jl"))'

cd ~/tmp-test2/LS2v/Simulation1
mpirun -np 1 "$BUILD_DIR/romsM" roms.in | tee roms.out
