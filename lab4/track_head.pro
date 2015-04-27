PRO map_plane, fileTag, dStatus, gLong, interv, nSpec
;+
; OVERVIEW
; --------
; will point Leuschner at coordinates specified by gLat, then grab spectra.
; will store the fits files in ./data/ compile rot_mats prior to running this
;
; CALLING SEQUENCE
; ----------------
; map_plane, fileTag, dStatus, gLat, interv, nSpec
;
; PARAMETERS
; ----------
; fileTag: string
; 		the string by which to label your tags. each observation will be
; 		incremented with triple precision for identification
;     looking for 'fileTag_on_xxx.fits', where xxx is the increment
;	dStatus: string
;			either 'on' or 'off' indicates whether the noise diode is on or off
; gLong: list
;			the start and stop coordinates of the galactic longitude in
; 		degrees...please make them even numbers
; interv: float
; 		the increment interval between the galactic longitude coordinates 
; nSpec: integer
; 		the number of spectra to take
;-
	j = 0                                            ; initialize filetag count
	FOR i=gLong[0], gLong[1], interv DO BEGIN
		sj = STRING(j, FORMAT='(I03)')                 ; string-ify filetag count
		filename = './data/'+fileTag+'_'+dStatus+'_'+sj+'.fits'  ; filename
		raDec = gal_raDec(i, 0)                    ; (l,b)->(ra,dec) in degrees
		ra = raDec[0]                                        ; unpack ra
		dec = raDec[1]                                       ; unpack dec
	  azAlt=raDec_azAlt(ra,dec, systime(/julian, /utc))    ; (ra,dec)->(az,alt)
    az=azAlt[0]                                          ; unpack az
    alt=azAlt[1]                                         ; unpack alt
    dishStatus=pointdish(alt, az)                        ; point dish
		print, '!!!DISH STATUS!!!', dishStatus               ; good if prints 0
		result = leuschner_rx(filename, nSpec, i, 0, 'ga')   ; grab spectra
		j+=1                                                 ; increment filename
	ENDFOR
END
		
PRO map_times, gLat, gLong, jDay, altArr, azArr
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
;     a list of galactic latitudes over which you wanna be
;     lookin' specified in degrees
; gLong: list
;     a list of falactic longitudes over which you wanna be
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
	azArr = []
  FOR t = jDay, endTime, oneHour DO BEGIN
     azAlt = raDec_azAlt(ra, dec, t)   ; get (az,alt) in degrees
     az = azAlt[*,0]
     alt = azAlt[*,1]                  ; get only altitudes
     altArr = [[altArr],[alt]]         ; make a nice array
                                ; each row corresponds to a julian day,
                                ; each column corresponds to a
                                ; coordinate
		azArr = [[azArr],[az]]
		; NOTE, allowed ranges: 12<alt<87, -5<az<365
  ENDFOR
END
