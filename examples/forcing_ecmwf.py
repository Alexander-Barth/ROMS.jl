#!/usr/bin/env python

# More information about the ECMWF Web API and how to register
# is available here:
# https://www.ecmwf.int/en/forecasts/access-forecasts/ecmwf-web-api
# https://confluence.ecmwf.int/display/WEBAPI/Access+ECMWF+Public+Datasets

# Once logged-in at https://www.ecmwf.int/
# retrieve your key
# https://api.ecmwf.int/v1/key/

# Parameter database
# https://apps.ecmwf.int/codes/grib/param-db
# For example, code 146 represents "Surface sensible heat flux"
# https://apps.ecmwf.int/codes/grib/param-db?id=146
# https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation#ERA5:datadocumentation-Meanrates/fluxesandaccumulations

import ecmwfapi
from datetime import datetime
from ecmwfapi import ECMWFDataServer

def download(xr,yr,tr,filename):
    c = ecmwfapi.ECMWFService('mars')

    fmt = '%Y-%m-%d'

    req2 = {
        'class':   'od',
        'expver':  '1',
        'date':    tr[0].strftime(fmt) + '/to/' + tr[1].strftime(fmt),
        'levtype': 'sfc',
        'grid':    '0.125/0.125',
        'param':   '146.128/147.128/151.128/164.128/165.128/166.128/167.128/168.128/175.128/176.128/177.128/180.128/181.128/182.128/205.128/228.128/34.128/58.128',
        'step':    '3/6/9/12',
        'stream':  'oper',
        'target':  'output',
        'time':    '00/12',
        'type':    'fc',
        'area':    '%g/%g/%g/%g' % (yr[0],xr[0],yr[1],xr[1]),
        'format':  'netcdf'
    }

    print(req2)
    c.execute(req2, filename)


if __name__ == '__main__':
    fmt = '%Y-%m-%d'

    # range of longitude (east, west)
    xr = [7.5, 12.375]

    # range of latitude (south, north)
    yr = [41.875, 44.625]

    # time range (stard, end)
    # the datetime function expects year, month and day
    # Note: it should contain 1 day more than the simulation time range of ROMS
    # If ROMS starts at 1 January 2000, you will need data the 31 December 2000
    tr = [datetime(2018,12,1),datetime(2020,1,1)]

    # output file name
    filename = 'ecmwf_operational_archive_' + tr[0].strftime(fmt) + '_' + tr[1].strftime(fmt) + '.nc'

    download(xr,yr,tr,filename)
