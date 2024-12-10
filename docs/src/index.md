This package allows to setup necessary files for the [ROMS ocean model](https://www.myroms.org/).

This tutorial is for students following the ULiège lecture OCEA0036-1 but might be useful for others as well.

## Using for the first time a Linux (or UNIX-like) environment?

If you are familiar with Linux and the command line you can skip to section.

* Essential shell commands:
    * `pwd`: print the name of the current working directory
    * `ls`: list all files and directories in the current working directory
    * `cd directory_name`: change directory; "go inside" the directory
    * `mkdir directory_name`: create a directory
    * `cp source destination`: copy a file
    * `mv source destination`: move a file
    * `rm file`: remove a file (permanently)
    * `find directory_name -name "*foo*"`: find all files under `directory_name` (including sub-directories) whose name contains `foo`.
    * `diff -u --color file1 file2`: compare two text files
    * `gnome-text-editor filename &`, `pluma filename &` or `editor filename &`: open a text editor to edit a file.

* Shell keyboard short cuts (also applicable to a julia session):
    * `up-arrow`: show previous command (similarly `down-arrow` show next command)
    * `TAB`: complete command or file/directory name if it is unambiguous
    * `TAB TAB`: show all possible commands or file/directory name if multiple possibilities exists
    * `Control-R` and type `some_string`: Search for a previously executed command which includes `some_string`.
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

## Registration

Please register at:
* [CMEMS (Copernicus Marine Environment Monitoring Service)](https://marine.copernicus.eu/services-portfolio/register-now/)

To generate new forcing fields, register at (optional):
* [ECMWF (European Centre for Medium-Range Weather Forecasts)](https://apps.ecmwf.int/registration/). To access the operational forecast on the MARS service you will need a special permissions granted by your national weather service (in Europe). The default permission will let you access e.g. ERA5 dataset.


## Required software

The tutorial can be run either:

1. on your computer using a preconfigured virtual machine
2. on the machines of the ULiège computer room
3. directly on your computer (but all software has to be installed beforehand) if you are using Ubuntu/Debian. Other Linux OS will work too, but the installation instructions must be adapted. Mac OS and Windows (using e.g. Windows Subsystem for Linux) might work also; but if you are not using Linux, it is preferable to the the virtual machine.
4. on the GHER notebook server ([https://notebook-gher.uliege.be/](https://notebook-gher.uliege.be/)) for ULiège students.


## Preconfigured virtual machine

A preconfigured virtual machine is available [here](https://data-assimilation.net/upload/OCEA0036/Ubuntu-24.04-MATE-Julia-ROMS.ova). You also need:

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

Note, it is not necessary for this tutorial to update the whole operating system.

## Installation on Debian/Ubuntu/Linux (or UNIX-like operating systems)

If you do not use this virtual machine the following software need to be installed:

* [Julia](https://julialang.org/downloads/). Under Linux, you can install Julia with the following shell commands:

```bash
curl -fsSL https://install.julialang.org | sh
```

During installation, you can confirm all default choices.
More information is available [here](https://julialang.org/downloads/platform/).

Under Linux, you need to install also `python3-matplotlib` for PythonPlot. On Debian/Ubuntu, this packages can be installed by this command:


```bash
sudo apt install python3-matplotlib
```

* Julia package, `PythonPlot`, `NCDatasets`, `ROMS` which can be installed by:

```julia
using Pkg
Pkg.add("PythonPlot")
Pkg.add("NCDatasets")
Pkg.develop(url="https://github.com/Alexander-Barth/ROMS.jl")
```

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
* [MSYS2](https://www.msys2.org/)
* Linux virtual machine using e.g. VirtualBox
* ...

On MacOS X:
* [Homebrew](https://brew.sh/)
* ...

On Debian/Ubuntu, these packages can be installed by this command:

```bash
sudo apt install gfortran make perl netcdf-bin libnetcdff-dev libopenmpi-dev openmpi-bin git python3-pip python3-setuptools unzip
```

* For ECMWF data, you need the package `ecmwf-api-client` (optional). Follow the [installation instructions](https://confluence.ecmwf.int/display/WEBAPI/Access+ECMWF+Public+Datasets) (including the ECMWF key). For questions related to ECMWF data access please also consult [this document](https://www.ecmwf.int/en/forecasts/access-forecasts/ecmwf-web-api).
* Note that the ECMWF key is different from your ECMWF password.


### Install or update the ROMS.jl julia package

Install `ROMS.jl` by using the following command:

```julia
using Pkg
Pkg.develop(url="https://github.com/Alexander-Barth/ROMS.jl")
```

Make sure to use the latest version by using this shell commands:

```bash
cd .julia/dev/ROMS
git pull
```

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

These commands should return a basic usage info or the version number if they are correctly installed.

## Choise of area

Choose an area:

* What interesting processes are present in your studied area? (note: now we all use the Ligurian Sea)
* Are there in situ measurements available for your area? Look for temperature and salinity within your areas (for any time frame)
     * Check with [World Ocean Database](https://www.nodc.noaa.gov/OC5/SELECT/dbsearch/dbsearch.html)
     * [CMEMS in situ Thematic Assemble Centre (TAC)](https://marine.copernicus.eu/)
* Visualize a couple of downloaded profiles:
     * Hints: in Julia you can use the package [`NCDatasets`](https://github.com/Alexander-Barth/NCDatasets.jl)
     * How would you distribute the vertical resolution in your model represent this profile?

* Check that your longitude/latitude/time range model of your nested model is within longitude/latitude/time range of the outer model providing the boundary conditions

* Choose the domain such to avoid unnecessary open ocean boundary conditions


## ROMS configuration

* [01\_build\_roms.ipynb](01_build_roms.ipynb): compilation of the source code
* [02\_prep\_roms.ipynb](02_prep_roms.ipynb): creating input files
* [03\_run\_roms.ipynb](03_run_roms.ipynb): running the ROMS model
* [04\_plots.ipynb](04_plots.ipynb): plotting the results
