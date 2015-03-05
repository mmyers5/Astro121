FUNCTION track_bod, ra, dec, jDay
;+
; OVERVIEW
; --------
; will take right ascension and declination to calculate azimuth and
; altitude of a stellar body at the provided julian day. will also
; account for precession.
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension given in radians
; dec: float
;     the declination given in radians
; jDay: float
;     the julian day given in...days
;
; OUTPUTS
; -------
; azAlt: list
;     returns a tuple (az,alt) of precessed azimuth and altitude
;     coordinates
;-

  LST = ilst(juldate=jDay)           ; get local sidereal time in hr decimal
  LST = LST*(15.)*(!pi/180.) ; convert hr decimal to radians
  bLat = !dtor*(37.8732)     ; our latitude in degrees
  precess, ra, dec, 2000, 2015, /radian  ; precess coordinates

  raDec = [ [cos(dec)*cos(ra)],$  ; vectorize (ra,dec)
            [cos(dec)*sin(ra)],$
            [        sin(dec)] ]
  
  raDec_haDec = [ [cos(LST),  sin(LST), 0],$     ; (ra,dec)->(ha,dec)
                  [sin(LST), -cos(LST), 0],$
                  [       0,         0, 1] ]
  haDec_azAlt = [ [-sin(bLat),  0, cos(bLat)],$ ; (ha,dec)->(az,alt)
                  [         0, -1,         0],$
                  [ cos(bLat),  0, sin(bLat)] ]
  haDec = raDec_haDec ## raDec   ; rotate (ra,dec)-->(ha,dec)
  azAlt = haDec_azAlt ## haDec   ; rotate (ha,dec)-->(az,alt)
  az = atan(azAlt[1],azAlt[0])   ; get right ascension in radians
  alt = asin(azAlt[2])                ; get declination in radians
  azAlt = [[az],[alt]]           ; put together in tuple form
  RETURN, azAlt
END
