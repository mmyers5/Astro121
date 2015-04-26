PRO map_plane, fileTag, gLong, interv, nSpec
;+
; OVERVIEW
; --------
; will point Leuschner at coordinates specified by gLat, then grab spectra.
; will store the fits files in ./data/ MAKE SURE DIODE IS SET, compile rot_mats
;
; CALLING SEQUENCE
; ----------------
; map_plane, fileTag, gLat, interv, nSpec
;
; PARAMETERS
; ----------
; fileTag: string
; 		the string by which to label your tags. each observation will be
; 		incremented with triple precision for identification
; gLong: list
;			the start and stop coordinates of the galactic longitude in
; 		degrees...please make them even numbers
; interv: float
; 		the increment interval between the galactic longitude coordinates 
; nSpec: integer
; 		the number of spectra to take
;-
	j = 0              ; initialize filetag count
	FOR i=gLong[0], gLong[1], interv DO BEGIN
		sj = STRING(j, FORMAT='(I03)')                 ; string-ify filetag count
		filename = './data/'+fileTag+'_'+sj+'.fits'    ; generate full filename
		raDec = (gal_raDec(gLong, 0)                   ; (l,b)->(ra,dec) in degrees
		ra = raDec[0]                                        ; unpack ra
		dec = raDec[1]                                       ; unpack dec
		PRECESS, ra, dec, 2000, 2015                         ; precess coordinates
		ra = ra*(24./360)                                    ; convert ra to hours
		follow, ra, dec, duration = 20                       ; follow coordinate
		result = leuschner_rx(filename, nSpec, i, 0, 'ga')   ; grab spectra
	ENDFOR
END
		
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
