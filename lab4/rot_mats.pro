FUNCTION gal_raDec, gLong, gLat
;+
; OVERVIEW
; --------
; will take in galactic longitudes and galactic latitudes in degrees and
; convert them to right ascenson and declination in degrees in 2000
; equinox
;
; CALLING SEQUENCE
; ----------------
; result = gal_raDec(gLong, gLat)
;
; PARAMETERS
; ----------
; gLong: list
;     the galactic longitude (l) in degrees
; gLat: list
;     the galactic latitude (b) in degrees
;
; OUTPUTS
; -------
; raDec: list
;     the right ascensions and declinations of object where each column
;     is a pair of coordinates (ra,dec), i.e. to get the 20th
;     coordinate, use raDec[20,*]
;-
  gLong *= !dtor   ; convert coordinates to radians
  gLat *= !dtor    ; convert coordinates to radians
  vec = [[gLong], [gLat]] ; row 0 -> gLong, row 1 -> gLat
  
  gLongLat = [ [cos(vec[*,1])*cos(vec[*,0])] ,$ ; vectorize (l,b)
               [cos(vec[*,1])*sin(vec[*,0])] ,$ ; operation gives vectorized form
               [              sin(vec[*,1])]  ] ; in each column such that each column
                                                ; corresponds to a tuple of coordinates
  rotMatrix = transpose([ [-0.054876,  0.494109, -0.867666],$ ; get rotation matrix
                [-0.873437, -0.444830, -0.198076],$
                [-0.483835,  0.746982,  0.455984] ]) 
  raDec = rotMatrix ## gLongLat           ; rotate (l,b) -> (ra,dec)
                                          ; each column gets rotated 
  ra = atan(raDec[*,1], raDec[*,0])       ; unpack vectors
  dec = asin(raDec[*,2])                  ; of same shape as vec
  raDec = [[ra], [dec]]*!radeg            ; convert to degrees
  return, raDec                           ; (ra,dec) in degrees
END

FUNCTION raDec_azAlt, ra, dec, jDay
;+
; OVERVIEW
; --------
; will take in right ascensions and declinations in degrees for 2000
; equinox and rotate them into azimuth and altitude in degrees centered
; on leuschner for a given julian day in 2015 epoch
;
; CALLING SEQUENCE
; ----------------
; result = raDec_azAlt(ra, dec, jDay)
;
; PARAMETERS
; ----------
; ra: list
;     the right ascensions in 2000 equinox given in degrees
; dec: list
;     the declinations in 2000 equinox given in degrees
; jDay: float
;     the julian day given in julian days, UTC time
;
; OUTPUTS
; -------
; azAlt: list
;     the azimuths and altitudes of object where each column
;     is a pair of coordinates (az,alt), i.e. to get the 20th
;     coordinate, use azAlt[20,*], given in current epoch
;-
  ra*=!dtor
  dec*=!dtor
  LST = ilst(juldate=jDay)           ; get local sidereal time in hr decimal
  LST = LST*(15.)*!dtor              ; convert hr decimal to radians
  bLat = !dtor*(37.8732)             ; leuschner latitude in radians
  precess, ra, dec, 2000, 2015, /radian   ; precess coordinates
  vec = [[ra],[dec]]
  raDec = [ [cos(vec[*,1])*cos(vec[*,0])],$  ; vectorize (ra,dec)
            [cos(vec[*,1])*sin(vec[*,0])],$  ; vectorized forms in each column
            [              sin(vec[*,1])] ]
  raDec_haDec = [ [cos(LST),  sin(LST), 0],$     ; (ra,dec)->(ha,dec)
                  [sin(LST), -cos(LST), 0],$
                  [       0,         0, 1] ]
  haDec_azAlt = [ [-sin(bLat),  0, cos(bLat)],$  ; (ha,dec)->(az,alt)
                  [         0, -1,         0],$
                  [ cos(bLat),  0, sin(bLat)] ]
  haDec = raDec_haDec ## raDec       ; rotate (ra,dec)-->(ha,dec)
  azAlt = haDec_azAlt ## haDec       ; rotate (ha,dec)-->(az,alt)
  az = atan(azAlt[*,1],azAlt[*,0])   ; get azimuth in radians
  alt = asin(azAlt[*,2])             ; get altitude in radians
  azAlt = [[az], [alt]]*!radeg       ; put together and degree-ify
  RETURN, azAlt                      ; return (az,alt) in degrees
END
