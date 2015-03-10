PRO show_me_the_sun, endTime
;+
; OVERVIEW
; --------
; will point the telescope to the sun every twenty seconds. will also
; re-calibrate the system every hour
;
; CALLING SEQUENCE
; ----------------
; show_me_the_sun, endTime
; 
; PARAMETERS
; ----------
; endTime: float
;     when you want the observation to end in UTC julian days
;-
  homer      ; calibrate for the first time
  i = 0      ; initialize number of times of waiting
  WHILE systime(/julian, /utc) LT ENDTIME DO BEGIN
     isun, altSun, azSun, /aa               ; get azimuth and altitude of sun in degrees
     result = point2(az=azSun, alt=altSun)  ; point telescopes
     WAIT, 20                               ; wait before re-pointing
     IF i mod 180 EQ 0 THEN BEGIN           ; every 3600 seconds
        homer
     ENDIF
  ENDWHILE
END

PRO show_me_the_money, saveFile, endTime
;+
; OVERVIEW
; --------
; will point the telescope to the object every twenty seconds. will
; also "re-calibrate" the system with homer every hour. will be glorious
;
; CALLING SEQUENCE
; ----------------
; show_me_the_money, saveFile, endTime
;
; PARAMTERS
; ---------
; saveFile: string
;     the full filename of the save file where ra and dec are stored as
;     variables
; endTime: float
;     when you want the observation to end in julian days
;-
  restore, saveFile    ; get the ra and dec from a save file
  homer                ; calibrate for the first time
  i = 0                ; number of times had to wait 20 seconds
  WHILE systime(/julian, /utc) LT endTime DO BEGIN
     azAlt = find_bod(ra, dec, systime(/julian,/utc)) ; get instantaneous (az,alt)
     azAlt = !radeg*azAlt           ; convert (az,alt) to degrees
     result = point2(az=azAlt[0],alt=azAlt[1]) ; point telescopes
     WAIT, 20                        ; wait 20 seconds
     i+=1                            ; increment number by 1, i = 1+i
     IF i MOD 180 EQ 0 THEN BEGIN    ; every 3600 seconds
        homer                        ; re-calibrate telescope to 0
     ENDIF
     print, 'I live!'
  ENDWHILE
END

FUNCTION find_bod, ra, dec, jDay
;+
; OVERVIEW
; --------
; will take right ascension and declination to calculate azimuth and
; altitude of a stellar body at the provided julian day. will also
; account for precession.
;
; CALLING SEQUENCE
; ----------------
; result = find_bod(ra, dec, jDay)
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension in 2000 equinox given in radians
; dec: float
;     the declination in 2000 equinox given in radians
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
  bLat = !dtor*(37.8732)     ; our latitude in radians
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
  az = atan(azAlt[1],azAlt[0])   ; get azimuth in radians
  alt = asin(azAlt[2])           ; get altitude in radians
  azAlt = [[az],[alt]]           ; put together in tuple form
  RETURN, azAlt                  ; return (az,alt) in radians
END

PRO time_bod, ra, dec, jDay
;+
; OVERVIEW
; --------
; will give a 24 hour idea of where the stellar body will be in terms of
; altitude. result is a plot of altitude versus time in hours for our time zone
;
; CALLING SEQUENCE
; ----------------
; time_bod, ra, dec, jDay
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension in 2000 equinox given in radians
; dec: float
;     the declination in 2000 equinox given in radians
; jDay: float
;     will increment this over 24 hours to give a picture of the
;     altitude of stellar body. must be the julian day in utc.
;-

  endTime = jDay + 1     ; add a full day to julian day
  oneHour = 0.0416667    ; one hour in day units
  altArr = []            ; initialize a null array to hold data
  FOR t = jDay, endTime, oneHour DO BEGIN  ; for every hour in the jday
     alt = (find_bod(ra, dec, t))[1]       ; get altitude from function above
     CALDAT, t, mo, day, yr, hr, min, sec  ; unpack julian info
     altArr = [ [altArr],[hr,alt] ]        ; append to data array
  ENDFOR
  ; plot altitude vs hr
  plot, altArr[0,*]-8, altArr[1,*], yrange = [-0.174533, !pi],$
        title='Altitude of Stellar Body in Time',$
        xtitle='Time (hrs)', ytitle='Altitude (rad)',$
        /xstyle, /ystyle, xrange=[0,24]
END
