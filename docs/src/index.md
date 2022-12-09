This package allows to setup necessary files for the [ROMS ocean model](https://www.myroms.org/).

## Tutorial

This tutorial is for students following the ULiège lecture OCEA0036-1 but might be useful for others as well.

### Using for the first time a Linux (or UNIX-like) environment?

* Essential shell commands:
    * `ls`: list all files and directories
    * `cd directory_name`: change directory
    * `pwd`: print the name of the current working directory
    * `mkdir`: create a directory
    * `cp source destiation`: copy a file
    * `mv source destiation`: move a file
    * `rm file`: remove a file (permanently)
    * `diff file1 file2`: compare two text files
    * `gedit filename &`, `pluma filename &` or `editor filename &`: open a text editor to edit a file.

* Shell keyboard short cuts (also applicable to a julia session):
    * `up-arrow`: show previous command (similarily `down-arrow` show next command)
    * `TAB`: complete command or file/directory name if it is unambigous
    * `TAB TAB`: show all possible commands or file/directory name if multiple possibilities exists
    * `Control-R` and type `some_string`: Search for a previsouly executed command which includes `some_string`.
    * `Control-C`: cancel the previous command (be careful to not to cancel your text editor session)
    * `Control-D`: close a shell session

* Special directories:
    * `.`: current directory
    * `..`: parent directory
    * `~`: home directory

* Please pay attention to the difference between upper- and lowercase letters
* Presence and absence of white space is also significant
* Avoid using directories and file names with a space in them, otherwise you need to put the directory in quotes (single or double quotes) or use black-slash (`\\`) in front of the white space. For example, shell command `cd My Directory Name` does not work, use one of the following instead:

```bash
cd "My Directory Name"
cd 'My Directory Name'
cd My\ Directory\ Name
```

* Check out the [basic shell commands](https://diyhacking.com/linux-commands-for-beginners/) and [this tutorial](https://ryanstutorials.net/linuxtutorial/)

### Registration

Please register at:
* [ROMS (Regional Ocean Modeling System)](https://www.myroms.org/index.php?page=RomsCode).
* [CMEMS (Copernicus Marine Environment Monitoring Service)](http://marine.copernicus.eu/services-portfolio/register-now/)

To generate new forcing fields, register at (optional):
* [ECMWF (European Centre for Medium-Range Weather Forecasts)](https://apps.ecmwf.int/registration/). To access the operational forecast on the MARS service you will need a special permissions granted by your national weather service (in Europe). The default permission will let you access e.g. ERA5 dataset.


### Required software

The tutorial can be run either:

1. on your computer using a preconfigured virtual machine
2. on the machines of the ULiège computer room
3. directly on your computer (but all software has to be installed beforehand) if you are using Ubuntu/Debian. Other Linux OS will work too, but the installation instructions must be adapted. Mac OS and Windows (using e.g. Windows Subsystem for Linux) might work too. But if you are not using Linux, it is preferable to the the virtual machine.


#### Preconfigured virtual machine

A preconfigured virtual machine is available [here](http://data-assimilation.net/upload/OCEA0036/Ubuntu-20.04-MATE-Julia-ROMS.ova).

* Virtual Box requires the [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170) which should be installed before (as of Virtual Box version 7.0.4).
* Virtual Box can be installed from [here](https://www.virtualbox.org/wiki/Downloads).
* The OVA file must be imported in Virtual Box as explained in the [documentation](https://docs.oracle.com/cd/E26217_01/E26796/html/qs-import-vm.html).

The account `student` has the password `tritro`. In this virtual machine, all software is already pre-installed, but must be updated using this shell commands:

```bash
cd .julia/dev/ROMS
git pull
```

Then open a julia session (typing the `julia` command), and update all packages with:

```julia
using Pkg
Pkg.update()
```

Note, it is not necessary of this tutorial to update the whole operating system.

#### Installation on Ubuntu/Linux (or UNIX-like operating systems)

If you do not use this virtual machine the following software need to be installed:

* [Julia](https://julialang.org/downloads/). Under Linux, you can install Julia with the following shell commands:

```bash
cd /opt/
sudo wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.2-linux-x86_64.tar.gz
sudo tar -xvf julia-1.8.2-linux-x86_64.tar.gz
sudo rm julia-1.8.2-linux-x86_64.tar.gz
sudo ln -s /opt/julia-1.8.2/bin/julia /usr/local/bin/julia
```

where `1.8.2` should be replaced by the version number of the current stable release.
More information is available [here](https://julialang.org/downloads/platform/).

Under Linux, you need to install also `python3-matplotlib` for PyPlot. On Debian/Ubuntu, this packages can be installed by this command:


```bash
sudo apt install python3-matplotlib
```

* Julia package, `PyPlot`, `NCDatasets`, `ROMS` which can be installed by:

```julia
using Pkg
Pkg.add("PyPlot")
Pkg.add("NCDatasets")
Pkg.develop(url="https://github.com/Alexander-Barth/ROMS.jl")
```

* ROMS source. This example uses the version 4.0 of ROMS. We assume that the ROMS source is copied in `~/src/roms`:

```bash
mkdir ~/src/
cd ~/src/
git clone "https://www.myroms.org/git/src" roms
cd roms
git checkout roms-4.0
```

For the git command, you will cneed to provide your ROMS username and password.


Other required software typically available from a package manager:
* A Fortran 90 compiler (e.g. gfortran)
* GNU make
* NetCDF (including headers files for development and the tools `ncdump`, `nf-config`)
* perl
* Python and pip
* MPI (optional)
* git (optional)

Note that all libraries (NetCDF and MPI) must be compiled with the same Fortran compiler.

On Windows, various ways exist to install gfortran, GNU make and other dependencies:
* Windows Subsystem for Linux
     * [Installation guide](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide)
     * [FAQ (in particular exchanging files)](https://docs.microsoft.com/en-us/windows/wsl/faq)
* [Cygwin](https://www.cygwin.com/)
* [MINGW](http://www.mingw.org/)
* Linux virtual machine using e.g. VirtualBox
* ...

On MacOS X:
* Homebrew https://brew.sh/
* ...

On Debian/Ubuntu, these packages can be installed by this command:

```bash
sudo apt install gfortran make perl netcdf-bin libnetcdff-dev libopenmpi-dev openmpi-bin git python3-pip python3-setuptools unzip
```

* For CMEMS data, you need the python package `motuclient` ([installation instructions](https://github.com/clstoulouse/motu-client-python#Installation)).
For example:

```bash
# to install a specific version use
python3 -m pip install --user motuclient==1.8.6
# or to install the latest version use:
# python3 -m pip install --user motuclient
```

I advice you to use version 1.8.6 of motuclient because of [this issue](https://github.com/clstoulouse/motu-client-python/issues/27).
Normally you will see the warning `WARNING: The script motuclient is installed in '.../.local/bin' which is not on PATH. Consider adding this directory to PATH`.
You need to add the following line to the file `.bashrc` located in your home directory (at the end of this file on a separate line):

```
export PATH="$HOME/.local/bin:$PATH"
```

In a terminal execute the following so that this change takes effect:

```bash
source ~/.bashrc
```


* For ECMWF data, you need the pacakge `ecmwf-api-client` (optional). Follow the [installation instructions](https://confluence.ecmwf.int/display/WEBAPI/Access+ECMWF+Public+Datasets) (including the ECMWF key). For questions related to ECMWF data access please also consult [this document](https://www.ecmwf.int/en/forecasts/access-forecasts/ecmwf-web-api).
* Note that the ECMWF key is different from your ECMWF password.

### Check your environment

* Check julia version:

```bash
julia --version
```

* Check the Fortran Compiler

```bash
gfortran --version
```

* MPI
```bash
mpif90 --version
mpirun --help
```

* NetCDF
```bash
nf-config --all
```
*or* the old name `nc-config`:

```bash
nc-config --all
```

If you have `nc-config` (with Fortran support) but not `nf-config`, you can run the following:

``` bash
ln -s /usr/bin/nc-config $HOME/bin/nf-config
```
Or set later the environemt variable `NF_CONFIG` to `nc-config`.

* Check the `motuclient` (it may return `vUnknown`, but it should not return `No module named motuclient`)

```bash
motuclient --version
```

These commands should return a basic usage info or the version number if they are correctly installed.

### Data

* The full [GEBCO bathymetry](https://dox.ulg.ac.be/index.php/s/iEh7ompNdj8AN2p/download) (the file `gebco_30sec_1.nc` is already included in the virtual machine)


### Area

Choose an area:

* What interesting processes are present in your studied area? (note: now we all use the Ligurian Sea)
* Are there in situ measurements available for your area? Look for temperature and salinity within your areas (for any time frame)
     * Check with [World Ocean Database](https://www.nodc.noaa.gov/OC5/SELECT/dbsearch/dbsearch.html)
     * [CMEMS in situ Thematic Assemble Centre (TAC)](http://marine.copernicus.eu/)
* Visualize a couple of downloaded profiles:
     * Hints: in Julia you can use the package [`NCDatasets`](https://github.com/Alexander-Barth/NCDatasets.jl)
     * How would you distribute the vertical resolution in your model represent this profile?

* Check that your longitude/latitude/time range model of your nested model is within longitude/latitude/time range of the outer model providing the boundary conditions

* Choose the domain such to avoid unnecessary open ocean boundary conditions

### Atmospheric forcing fields


* For the Ligurian Sea, necessary parameters have already been prepared and are available in the file [ROMS-implementation.zip](https://dox.ulg.ac.be/index.php/s/nH8u2DrI1m9mMbC). It containts data download the from
the ECMWF operational archive (`Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc`). This NetCDF file needs to be converted by the julia function `ROMS.prepare_ecmwf`.

* The remaining of this section explained how to download data from the ECMWF operational archive (e.g. for a different domain). These instructions are not needed now.
* Adapt the file name, longitude/latitude and time range (start one day earlier, and finish one day later) in [`forcing_ecmwf.py`](https://github.com/Alexander-Barth/ROMS.jl/blob/master/examples/forcing_ecmwf.py) and execute the script as follows:

```bash
python3 forcing_ecmwf.py
```

List of variables (*: quantities accumulated over the integration period ("step"))

| NetCDF Variable name | Description |
|----------------------|----------|
| msl | Mean sea level pressure |
| u10 | 10 metre U wind component |
| v10 | 10 metre V wind component |
| t2m | 2 metre temperature |
| d2m | 2 metre dewpoint temperature |
| tcc | Total cloud cover* |
| sshf | Surface sensible heat flux* |
| strd | Surface thermal radiation downwards* |
| ssr | Surface net solar radiation* |
| str | Surface net thermal radiation* |
| ewss | Eastward turbulent surface stress* |
| nsss | Northward turbulent surface stress* |
| e | Evaporation* |
| ro | Runoff* |
| tp | Total precipitation* |
| sst | Sea surface temperature |
| par | Photosynthetically active radiation at the surface* |

### Generate initial, boundary conditions and forcing files

* Adapt the [`example_config.jl`](https://raw.githubusercontent.com/Alexander-Barth/ROMS.jl/master/test/example_config.jl) file and call it `yourdomain_config.jl` where you replace `yourdomain` by the the name of your domain (lowercase and without space). For the Ligurian Sea, use `liguriansea_config.jl`.

    * Longitude/latitude bounding box
    * File paths
    * Time range
    * ...

* For CMEMS boundary conditions:
    * You may need to adapt `service_id`, `motu_server` and `mapping` (if model is outside the Mediterranean Sea)
    * Data will be downloaded and saved in NetCDF by "chunks" of 60 days in the folder `OGCM` under the content of the variable `basedir`
    * You need to remove the files in this directory if you rerun the script with a different time range.

* Run in Julia
```julia
include("yourdomain_config.jl")
```

* Check the resulting files: bathymetry, initial conditions, boundary conditions, interpolated model (`clim` file) and visualize the these files along some sections.


### ROMS compilation

* Create a directory (avoid directory names with spaces) for your model configuration
* Compile ROMS:
    * configure ROMS by creating a file `yourdomain.h` (e.g. `liguriansea.h` for the Ligurian Sea):

```C
#define UV_ADV                    /* turn ON advection terms */
#define UV_COR                    /* turn ON Coriolis term */
#define DJ_GRADPS                 /* Splines density  Jacobian (Shchepetkin, 2000) */
#define NONLIN_EOS                /* define if using nonlinear equation of state */
#define SALINITY                  /* define if using salinity */
#define SOLVE3D                   /* define if solving 3D primitive equations */
#define MASKING                   /* define if there is land in the domain */
#define TS_U3HADVECTION           /* Third-order upstream horizontal advection of tracers */
#define TS_C4VADVECTION           /* Fourth-order centered vertical advection of tracers */
#define TS_DIF2                   /* use to turn ON or OFF harmonic horizontal mixing  */
#define MIX_S_UV                  /* mixing along constant S-surfaces */
#define UV_VIS2                   /* turn ON Laplacian horizontal mixing */
#define AVERAGES
#define UV_QDRAG
#define MIX_S_TS

#define  MY25_MIXING
#ifdef MY25_MIXING
# define N2S2_HORAVG
# define KANTHA_CLAYSON
#endif

#define ANA_BSFLUX                /* analytical bottom salinity flux */
#define ANA_BTFLUX                /* analytical bottom temperature flux */
#define ANA_SSFLUX

#define BULK_FLUXES               /* turn ON bulk fluxes computation */
#define CLOUDS
#define LONGWAVE
#define SOLAR_SOURCE
```

* Copy the script `build_roms.sh` to the directory `~/ROMS-implementation-test`

```bash
cd ~/ROMS-implementation-test
cp ~/src/roms/ROMS/Bin/build_roms.sh build_roms.sh
```

* Copy it to this directory and adapt it. Here is a list of changes that I made highlighted with the [diff tool](https://en.wikipedia.org/wiki/Diff_utility#Unified_format).
The lines in red have been replaced by the lines in green. The plus and minus signes indicates also what has been added or removed and the `@@` indicate line numbers. These markers do not have to be added manually to the file `build_roms.sh`.

```diff
 diff -u /home/abarth/src/roms/ROMS/Bin/build_roms.sh build_roms.sh
--- /home/abarth/src/roms/ROMS/Bin/build_roms.sh	2020-10-11 21:19:08.000000000 +0200
+++ build_roms.sh	2020-11-06 11:16:15.484841910 +0100
@@ -102,12 +102,12 @@
 # determine the name of the ".h" header file with the application
 # CPP definitions.

-export   ROMS_APPLICATION=UPWELLING
+export   ROMS_APPLICATION=LigurianSea

 # Set a local environmental variable to define the path to the directories
 # where all this project's files are kept.

-export        MY_ROOT_DIR=${HOME}/ocean/repository
+export        MY_ROOT_DIR=${HOME}
 export     MY_PROJECT_DIR=${PWD}

 # The path to the user's local current ROMS source code.
@@ -120,7 +120,7 @@
 # machine. This script is designed to more easily allow for differing paths
 # to the code and inputs on differing machines.

- export       MY_ROMS_SRC=${MY_ROOT_DIR}/trunk
+ export       MY_ROMS_SRC=${MY_ROOT_DIR}/src/roms

 # Set path of the directory containing makefile configuration (*.mk) files.
 # The user has the option to specify a customized version of these files
@@ -168,13 +168,13 @@

 #export        USE_OpenMP=on            # shared-memory parallelism

- export              FORT=ifort
-#export              FORT=gfortran
+# export              FORT=ifort
+export              FORT=gfortran
 #export              FORT=pgi

 #export         USE_DEBUG=on            # use Fortran debugging flags
  export         USE_LARGE=on            # activate 64-bit compilation
-#export       USE_NETCDF4=on            # compile with NetCDF-4 library
+export       USE_NETCDF4=on            # compile with NetCDF-4 library
 #export   USE_PARALLEL_IO=on            # Parallel I/O with NetCDF-4/HDF5


```

If you do not have the tool `nf-config`, you need to add this line `export NF_CONFIG=nc-config`.

For ROMS 4.0 and gfortran 11.2, you need to add `-fallow-argument-mismatch` to `FFLAGS` in `Compilers/Linux-gfortran.mk` from the
ROMS source files. This is expected to be fixed in upcoming version of ROMS.

* Review your changes with:

```bash
diff ~/src/roms/ROMS/Bin/build_roms.sh build_roms.sh
```

*  compile ROMS by running:

```bash
./build_roms.sh -j 2
```

where you need to replace `/path/to/previous` by the appropriate file path.

 * copy `varinfo.dat` from `~/src/roms/ROMS/External/varinfo.dat` in your current directory:

```bash
cp ~/src/roms/ROMS/External/varinfo.dat .
```


### ROMS model domain configuration

 * copy `roms.in` from `~/src/roms/User/External/roms.in` in the directory `~/ROMS-implementation-test`:

```bash
cp  ~/src/roms/User/External/roms.in .
```

 * check the glossary at the end of this file for the meaning of the keys that we will change
 * when editing this file, do not use "tabs".

 * adapt `MyAppCPP` and change it to `LIGURIANSEA`

 * adapt file names `VARNAME`, `GRDNAME`, `ININAME`, `BRYNAME`, `CLMNAME`, `FRCNAME` and `NFFILES`

 * also make sure that these variables are set (number of files with boundary conditions and climatology). If they do not exist, they need to be added (near `BRYNAME` for example).

```
 NBCFILES == 1
NCLMFILES == 1
```

 * change `Lm`, `Mm` and `N` based on the dimensions of your grid (make sure to read the glossary for these variable in `roms.in`)

 * read the desciption about "lateral boundary conditions" and adapt boundaries `LBC`:
    * use closed (`Clo`) for boundaries without sea-point
    * for open boundaries:
       * free-surface: Chapman implicit (`Cha`)
       * 2D U/V-momentum: Flather (`Fla`)
       * 3D U/V-momentum, temperature, salinity: Radiation with nudging (`RadNud`)
       * mixing TKE: Radiation (`Rad`)

 * set the starting time and time reference
```
DSTART = ...
TIME_REF =  18581117
```

where `DSTART` is here the number of days since 1858-11-17 or November 17, 1858 (see also [modified Julia day](https://en.wikipedia.org/wiki/Julian_day#Variants)). For instance the number of days since 2014-01-01 (year-month-day) can be computed by of following commands in Julia:

```julia
using Dates
Date(2020,1,1) - Date(1858,11,17)
```

The inverse operation can be done with:

```julia
using Dates
Date(1858,11,17) + Day(58849)
```

You can use `DateTime` if you want to specify hour, minutes or seconds.

* Adapt the length of a time step `DT` (in seconds) and number of time steps `NTIMES`
* Initially we choose:
    * `NTIMES` -> number of time step corresponding to 1 day (e.g. `24*60*60/DT` as `DT` is in seconds)
    * `NHIS`, `NAVG`-> number of time steps corresponding to 1 hour
    * `NRST` -> number of time steps correspond to 1 hour


### Nudging towards "climatology"

A flow relexation zone can be implemented in ROMS by using the followings settings:

```
LtracerCLM == T T  ! enable processing of CLIM data
LnudgeTCLM == T T  ! nudge to CLIM data
TNUDG == 2*10.0d0                    ! days
```

Make nudging on inflow is stronger than on outflow

```
OBCFAC == 10.0d0                      ! nondimensional
```

Set also `NUDNAME` to the file name create by the julia script.

### Run ROMS

#### Run ROMS without MPI

* To run ROMS without MPI, one need to disable MPI in `build_roms.sh`. The ROMS binary will be called `romsS` and call be called by:

```bash
./romsS < roms.in | tee roms.out
```

#### Run ROMS with MPI

* How many CPU cores does your machine have? You can use the command `top` in a shell terminal followed by `1`.
* In `build_roms.sh` set `USE_MPI=on` (which is actually the default value)
 * Recompile ROMS
 * Change in `roms.in` the parameters `NtileI` and `NtileJ`. The number of CPU cores should be `NtileI` * `NtileJ`.
 * Run ROMS with, e.g.

```bash
mpirun -np 4 ./romsM  roms.in | tee roms.out
```
where 4 is the number of cores to use. To use 4 CPUs, you need to set `NtileI` to 2 and `NtileJ` to 2.


With the command `tee` the normal screen output will be place in the file `roms.out` but still be printed on the screen.

* A problem? What does the error message say?
* Outputs are in `roms_his.nc` and `roms_avg.nc`, plot some variables like sea surface height and sea surface temperature at the beginning and the end of the simulation.

* In Julia, force figure 1 and to 2 to have the same color-bar.

```julia
figure(); p1 = pcolor(randn(3,3)); colorbar()
figure(); p2 = pcolor(randn(3,3)); colorbar()
p2.set_clim(p1.get_clim())
```

* If everything runs fine,
    * is the model still stable with a longer time steps (`DT`) ?
    * increase the number of time steps (`NTIMES`)
    * possibly adapt the frequency at which you save the model results (`NHIS`, `NAVG`,`NRST`)

### Interpreting ROMS output

* Check minimum and maximum value of the different parameters
```
 NLM: GET_STATE - Read state initial conditions,             t = 57235 00:00:00
                   (Grid 02, File: roms_nest_his.nc, Rec=0182, Index=1)
                - free-surface
                   (Min = -4.63564634E-01 Max = -3.63838434E-01)
```

* The barotropic, baroclinic and Coriolis Courant number should be smaller than 1

```
 Minimum barotropic Courant Number =  2.09670689E-02
 Maximum barotropic Courant Number =  5.56799674E-01
 Maximum Coriolis   Courant Number =  1.71574766E-03
```

* Information
    * energy (kinetic, potential, total) and volume
    * maximum Courant number

```
   STEP   Day HH:MM:SS  KINETIC_ENRG   POTEN_ENRG    TOTAL_ENRG    NET_VOLUME  Grid
          C => (i,j,k)       Cu            Cv            Cw         Max Speed

 346200 57235 00:00:00  2.691184E-03  1.043099E+04  1.043099E+04  6.221264E+13  01
          (079,055,30)  9.266512E-02  4.949213E-02  0.000000E+00  1.081862E+00
```


### Validation

Check out satellite data (e.g. sea surface temperature, sea surface height) at:
* [CMEMS](http://marine.copernicus.eu/)
* [PODAAC NASA](https://podaac.jpl.nasa.gov/)

Make some comparison with satellite and the downloaded in situ observation

### Hydrodynamic model troubleshooting

[Hydrodynamic model troubleshooting](https://github.com/gher-ulg/Documentation/wiki/Hydrodynamic-model-troubleshooting)


### More information

* [ROMS Wiki](https://www.myroms.org/wiki/)
* [ROMS Wiki Frequently Asked Questions](https://www.myroms.org/wiki/Frequently_Asked_Questions)
* K. Hedström. 2016. [Technical Manual for a Coupled Sea-Ice/Ocean Circulation Model (Version 4)](https://github.com/kshedstrom/roms_manual/blob/master/roms_manual.pdf). U.S. Dept. of the Interior, Bureau of Ocean Energy Management, Alaska OCS Region. OCS, Study BOEM 2016-037. 176 pp.
