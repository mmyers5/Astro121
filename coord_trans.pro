PRO hadec_radec, jDay
;+
; OVERVIEW
; --------
; converts hour angle and declination to right ascension and declination
; using matrix operations
;
; PARAMETERS
; ----------
; jDay: float
;     the julian day of measurements
; az: float
;     the azimuthal angle in radians (0)
; alt: float
;     the altidude angle, which is zenith (pi/2)
;
; OUTPUTS
; -------
; raDec: list
;     the values of right ascension and declination
;-

  ; initializing values
  caldat, jDay, mo, day, yr, hr, min, sec       ; unpack jday to get local times
  gHr = hr - 8                                  ; get hr to be in gmt time
  alt = !dtor*(32.43)                          ; we were looking straight up, 90 degrees
  az = !dtor*(137.60)                            ; arbitrary
  berkLong = !dtor*(-122.268133)                ; longitude of berkeley in radians
  berkLat = !dtor*(37.875463)                   ; latitude of berkeley in radians
  berkLat = !dtor*(41.36)  ; test
  solarTime = [gHr*(360./24)]$                  ; convert hrs to degrees
             +[min*(360./24)*(1./60)]$          ; convert minutes to degrees
             +[sec*(360./24)*(1./60)*(1./60)]   ; convert seconds to degrees
  solarTime = !dtor*solarTime                   ; convert to radians

  LST = solarTime + berkLong                    ; get local mean sidereal time

  ; rotation matrices
  haDec_raDec = [ [cos(LST),  sin(LST), 0],$    ; matrix goes from (ha,dec) -> (ra,dec)
                  [sin(LST), -cos(LST), 0],$
                  [0,                0, 1] ]

  azAlt_haDec = [ [-sin(berkLat), 0, cos(berkLat)],$ ; matrix gors from (az,alt) -> (ha,dec)
                  [0,            -1,            0],$
                  [cos(berkLat),  0, sin(berkLat)] ]
  
  azAlt = [ [cos(alt)*cos(az)],$           ; get rectangular vector of azimuth and altitude
            [cos(alt)*sin(az)],$
            [        sin(alt)] ]

  ; operations
  haDec = azAlt_haDec ## azAlt             ; convert (az,alt) to (ha,dec)
  raDec = haDec_raDec ## haDec             ; convert (ha,dec) to (ra,dec)
  print, haDec
END

