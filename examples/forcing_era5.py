# More information about ERA5 products may be found here:
# https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels

# First, set up the CDS API with these directions:
# https://confluence.ecmwf.int/display/CKB/How+to+install+and+use+CDS+API+on+macOS

import cdsapi

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type': 'reanalysis',
        'format': 'netcdf',
        'variable': [
            '10m_u_component_of_wind', '10m_v_component_of_wind', '2m_dewpoint_temperature',
            '2m_temperature', 'mean_eastward_turbulent_surface_stress', 'mean_evaporation_rate',
            'mean_northward_turbulent_surface_stress', 'mean_sea_level_pressure', 'mean_surface_downward_long_wave_radiation_flux',
            'mean_surface_latent_heat_flux', 'mean_surface_net_long_wave_radiation_flux', 'mean_surface_net_short_wave_radiation_flux',
            'mean_surface_sensible_heat_flux', 'mean_total_precipitation_rate', 'total_cloud_cover',
        ],
        'year': [
            '2021',
        ],
        'month': [
            '08', '09',
        ],
        'day': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
            '13', '14', '15',
            '16', '17', '18',
            '19', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '30',
            '31',
        ],
        'time': [
            '00:00', '01:00', '02:00',
            '03:00', '04:00', '05:00',
            '06:00', '07:00', '08:00',
            '09:00', '10:00', '11:00',
            '12:00', '13:00', '14:00',
            '15:00', '16:00', '17:00',
            '18:00', '19:00', '20:00',
            '21:00', '22:00', '23:00',
        ],
        'area': [
            36, -69, 27,
            -62,
        ],
    },
    'era5_21.nc')
