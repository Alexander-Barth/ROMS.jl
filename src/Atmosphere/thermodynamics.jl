vapor_pressure_Tetens(T) = 6.1078 * exp( 17.27 * T / (T + 237.3))


"""
    e = ROMS.vapor_pressure_Buck(T)

actual vapor pressure in hPa (millibars) from dewpoint temperature `T` in degree Celsius
using using [Buck (1996)](https://en.wikipedia.org/w/index.php?title=Arden_Buck_equation&oldid=946509994). If `T` is the air temperature, then  `e` is the saturated vapor
pressure over liquid water is given by:

``
e(T) = 6.1121 \\exp \\left(\\left( 18.678 - \\frac{T} {234.5}\\right)\\left( \\frac{T} {257.14 + T} \\right)\\right)
``
"""
vapor_pressure_Buck(T) = 6.1121 * exp( (18.678 - T/234.5) * T / (257.14 + T))


"""
    e = ROMS.vapor_pressure(T)

actual vapor pressure in hPa (millibars) from dewpoint temperature `T` in degree Celsius
using using [1]. If `T` is the air temperature, then  `e` is the saturated vapor
pressure over liquid water is given by:

``
e(T) = 6.11 \\cdot 10 ^ {\\left(  \\frac{7.5 T}{237.7 + T} \\right)}
``

[1] https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
vapor_pressure(T) = 6.11 * 10.0 ^ (7.5 * T / (237.7 + T))



"""
    rh = ROMS.relative_humidity(temperature_2m_C,dew_temperature_2m_C)

Compute the relative humidity (between 0 and 100) from temperature at 2 m, and dew_temperature at
2 m) both in degree Celsius)

[1] https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
function relative_humidity(temperature_2m_C,dew_temperature_2m_C)
    100 * vapor_pressure(dew_temperature_2m_C) / vapor_pressure(temperature_2m_C)
end


"""
    λ = ROMS.latent_heat_of_vaporization(T)

Compute the latent heat of vaporization `λ` (J/kg) of water at temperature `T` (in
degree Celsius).

The function implements equation 2.55 (page 38) of
[Foken, T, 2008: Micrometeorology. Springer, Berlin, Germany](https://link.springer.com/content/pdf/10.1007/978-3-540-74666-9.pdf).
"""
latent_heat_of_vaporization(Tair) = 2500827 - 2360 * Tair
