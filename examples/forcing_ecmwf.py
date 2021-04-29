#!/usr/bin/env python

# More information about the ECMWF Web API and how to register
# is available here:
# https://www.ecmwf.int/en/forecasts/access-forecasts/ecmwf-web-api
# https://confluence.ecmwf.int/display/WEBAPI/Access+ECMWF+Public+Datasets

import ecmwfapi
from datetime import datetime
from ecmwfapi import ECMWFDataServer

def download(xr,yr,tr,filename):
    c = ecmwfapi.ECMWFService('mars')

    fmt = '%Y-%m-%d'

    req2 = {
        'class': 'od',
        'expver': '1',
        'date': tr[0].strftime(fmt) + '/to/' + tr[1].strftime(fmt),
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
    # longitude range
    xr = [7.5, 12.375]
    # latitude range
    yr = [41.875, 44.625]
    # time range range
    tr = [datetime(2018,12,1),datetime(2020,1,1)]
    # file name
    filename = 'ecmwf_operational_archive_' + tr[0].isoformat() + '_' + tr[1].isoformat() + '.nc'

    download(xr,yr,tr,filename)
