PRO map_times, gLat, gLong, jDay, altArr
;+
; OVERVIEW
; --------
; will map the time that the object specified by gLat and gLong is up by
; creating a grid that will sweep through the values given by gLat and
; gLong. plot will show snapshot of the area with respect to altitude at
; leuschner for every 30 minutes. please compile rot_mats before you run
; this business
;
; CALL SEQUENCE
; -------------
; map_times, gLat, gLong, jDay, altArr
;
; PARAMETERS
; ----------
; gLat: list
;     a range of galactic latitudes over which you wanna be
;     lookin' specified in degrees
; gLong: list
;     a range of falactic longitudes over which you wanna be
;     lookin' specified in degrees
; jDay: float
;     beginning of timeframe to look at in julian days
;- 
  raDec = gal_raDec(gLong, gLat)   ; get (ra,dec) in degrees
  ra = raDec[*,0]                  ; get only ra portion
  dec = raDec[*,1]                 ; get only dec portion
  endTime = jDay + 1               ; add 24 hours to julian day
  oneHour = 1/24.                  ; one hour in day units
  altArr = []                      ; init null array to hold alts
  FOR t = jDay, endTime, oneHour DO BEGIN
     azAlt = raDec_azAlt(ra, dec, t)   ; get (az,alt) in degrees
     alt = azAlt[*,1]                  ; get only altitudes
     altArr = [[altArr],[alt]]         ; make a nice array
                                ; each row corresponds to a julian day,
                                ; each column corresponds to a
                                ; coordinate
  ENDFOR
  
END
