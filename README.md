# ROMS.jl

[![Build Status](https://github.com/Alexander-Barth/ROMS.jl/workflows/CI/badge.svg)](https://github.com/Alexander-Barth/ROMS.jl/actions)<!-- [![Build Status Windows](https://ci.appveyor.com/api/projects/status/github/Alexander-Barth/ROMS.jl?branch=master&svg=true)](https://ci.appveyor.com/project/Alexander-Barth/roms-jl) -->
[![Coverage Status](https://coveralls.io/repos/Alexander-Barth/ROMS.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/Alexander-Barth/ROMS.jl?branch=master) [![codecov.io](http://codecov.io/github/Alexander-Barth/ROMS.jl/coverage.svg?branch=master)](http://codecov.io/github/Alexander-Barth/ROMS.jl?branch=master) <!-- [![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://alexander-barth.github.io/ROMS.jl/stable/) -->
[![documentation latest](https://img.shields.io/badge/docs-dev-blue.svg)](https://alexander-barth.github.io/ROMS.jl/dev/)

# Installation

Install ROMS.jl in julia 1.6 or later with the folling command executed in Julia:

```julia
using Pkg
Pkg.add(url="https://github.com/Alexander-Barth/ROMS.jl", rev="master")
```

# Data sources

The following data sources have been tested:

* Bathymetry
    * [GEBCO](https://www.gebco.net/data_and_products/gridded_bathymetry_data/)
* Initial and boundary condition from:
    * [CMEMS](https://marine.copernicus.eu/)
    * [HYCOM GOFS](https://www.hycom.org/dataserver/)
* Atmospheric forcings:
    * ECMWF:
         * Operational forecasts (obtained from the python [ECMWF API](https://www.ecmwf.int/en/computing/software/ecmwf-web-api))
         * ERA 5 (obtained from the [Climate Data store](https://cds.climate.copernicus.eu/) using [CDSAPI.jl](https://github.com/JuliaClimate/CDSAPI.jl))
    * GFS from the [NCAR Research Data Archive](https://rda.ucar.edu/thredds/catalog/files/g/ds084.1/catalog.html)

Download scripts for ECMWF data are in [examples](/examples).

Contributions to add other data sources are welcome!

# Documentation

Documentation is available [here](https://alexander-barth.github.io/ROMS.jl/dev/).

# Credits

Thanks to Hernan G. Arango and John Wilkin from the ROMS/TOMS Group for the
matlab scripts to process the ECMWF fields and vertical coordinate transformations (released under [a MIT/X style license](https://www.myroms.org/main.php?page=License_ROMS))
and Pierrick Penven for the matlab script allowing to smooth the bathymetry (released under the GPL).
