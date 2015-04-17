PRO hadec_radec, jDay, raDec
;+
; OVERVIEW
; --------
; converts hour angle and declination to right ascension and declination
; using matrix operations using only given julian day. specifically for
; measurements made while looking at zenith in berkeley
;
; PARAMETERS
; ----------
; jDay: float
;     the julian day of measurements
;
; OUTPUTS
; -------
; raDec: list
;     the values of right ascension and declination in radians in the
;     form of a tuple (ra,dec)
;-

  ; initializing values
  caldat, jDay, mo, day, yr, hr, min, sec       ; unpack jday to get local times
  gHr = hr - 8                                  ; get hr to be in gmt time
  alt = !pi/2                                   ; altitude 
  az = 0                                        ; azimuthal angle
  berkLong = !dtor*(-122.268133)                ; longitude of berkeley in radians
  berkLat = !dtor*(37.875463)                   ; latitude of berkeley in radians

  LST = ilst(jDay)                              ; get LST in hr decimal
  LST = (LST)*(15)*(!pi/180.)                   ; convert LST to rad
  ; rotation matrices
  haDec_raDec = [ [cos(LST),  sin(LST), 0],$    ; matrix goes from (ha,dec) -> (ra,dec)
                  [sin(LST), -cos(LST), 0],$
                  [0,                0, 1] ]
  azAlt_haDec = [ [-sin(berkLat), 0, cos(berkLat)],$ ; matrix goes from (az,alt) -> (ha,dec)
                  [0,            -1,            0],$
                  [cos(berkLat),  0, sin(berkLat)] ]
  ; vectorizing altitude and azimuth
  azAlt = [ [cos(alt)*cos(az)],$           ; get rectangular vector of azimuth and altitude
            [cos(alt)*sin(az)],$
            [        sin(alt)] ]
  ; operations
  haDec = azAlt_haDec ## azAlt             ; convert (az,alt) to (ha,dec)
  raDec = haDec_raDec ## haDec             ; convert (ha,dec) to (ra,dec)
  ; convert vector to ra and dec
  dec = asin(raDec[2])                     ; declination in radians
  ra = atan(raDec[1],raDec[0])             ; right ascension in radians  
  raDec = [ra,dec]                         ; put together into a tuple (ra,dec)
END

PRO radec_galactic, ra, dec, galactic
;+
; OVERVIEW
; --------
; will take in right ascension and declination coordinates in radians
; and convert them to galactic coordinates in radians
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension coordinates given in radians
; dec: float
;     the declination coordinates given in radians
;
; OUTPUTS
; -------
; galactic: list
;     the l (longitude) and b (latitude) coordinates given in radians,
;     in the form of a tuple (l,b)
;-
  radec_gal = [ [-0.054876, -0.873437, -0.483835],$         ; rotation matrix for epoch 2000
                [ 0.494109, -0.444830,  0.746982],$
                [-0.867666, -0.198076,  0.455984] ]
  raDec = [ [cos(dec)*cos(ra)],$                            ; vectorizing the right ascension and declination
            [cos(dec)*sin(ra)],$
            [        sin(dec)] ]
  galactic = radec_gal ## raDec                             ; matrix operation
  galb = asin(galactic[2])                                  ; getting galactic latitude
  gall = atan(galactic[1],galactic[0])                      ; getting galactic longitude
  galactic = [gall, galb]                                   ; tuple-izing

END
