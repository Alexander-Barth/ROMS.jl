#!/usr/bin/env python
import ecmwfapi
from datetime import datetime

def download(xr,yr,tr,filename):
    c = ecmwfapi.ECMWFService('mars')

    fmt = '%Y-%m-%d'

    req2 = {
        'class':   'ei',
        'expver':  '1',
        'dataset': 'interim',
        'date':    tr[0].strftime(fmt) + '/to/' + tr[1].strftime(fmt),
        'levtype': 'sfc',
        'grid':    '0.75/0.75',
        'param':   '58.128/146.128/147.128/151.128/164.128/165.128/166.128/167.128/168.128/175.128/176.128/177.128/180.128/181.128/182.128/205.128/228.128',
        'step':    '3/6/9/12',
        'stream':  'oper',
        'target':  'output',
        'time':    '00:00:00/12:00:00',
        'type':    'fc',
        'area':    '%g/%g/%g/%g' % (yr[0],xr[0],yr[1],xr[1]),
        'format':  'netcdf',
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
    tr = [datetime(2018,12,1),datetime(2018,12,5)]

    # output file name
    filename = 'ecmwf_interim_' + tr[0].strftime(fmt) + '_' + tr[1].strftime(fmt) + '.nc'

    download(xr,yr,tr,filename)
