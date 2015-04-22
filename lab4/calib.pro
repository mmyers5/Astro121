PRO loop_da_loop
;+
; OVERVIEW
; --------
; will loop through a range of galactic longitudes and grab the doppler
; velocities at those longitudes in the galactic plane. will then proceed to
; plot rotation curve of da stuff
;-
  lRange = findgen(90)    ;get longitude range 0<l<90
  velo = []                     ; create velocity array
  FOR i=0, 89 DO BEGIN
     param = {lonra:lRange[i], latdec:0.}       ; generate parameters 
     temp = doppler_it(param, systime(/JULIAN)) ; grab velocity in degrees
     velo = [velo, temp]                          ; append to velocity array
		 print, temp
  ENDFOR
  vSun = 220                    ; sun velocity in km/s
  rSun = 8.5                    ; sun distance from gc in kpc
  lRange *= !dtor
	rRange = sin(lRange)*rSun     ; the radius values 
	vR = [(velo/(rSun*sin(lRange))) + (vSun/rSun)]
	plot, rRange, vR
END

FUNCTION doppler_it, param, jDay
;+
; OVERVIEW
; --------
; will generate doppler velocity for given galactic coordinate (l,b)
;
; CALLING SEQUENCE
; ----------------
; doppler_it, param, jDay
;
; PARAMETERS
; ----------
; param: structure
;     the structure with tags filename, nspec, lonra, latdec, and system
;     to be filled as specified by leuschner_rx, really only uses lonra and
;			latdec heh
; jDay: float
;     the julian day of the observation
;
; OUTPUTS
; -------
; velo: float
;     the doppler shift velocity in km/s
;-
  nlat = 37.8732     ; set latitude and longitude of leuschner
  wlong = 122.2573
  ; get right ascension and declination in degrees
  raDec = gal_raDec(param.lonra, param.latdec)
  ra=raDec[0]
  dec = raDec[1]
  velo = (ugdoppler(ra, dec, jDay, nlat=nlat, wlong=wlong))[3]
  return, velo 
END
FUNCTION gal_raDec, gLong, gLat
;+
; OVERVIEW
; --------
; will take in galactic longitude and galactic latitude in degrees and
; convert them to right ascenson and declination in degrees in 2000 equinox
;
; CALLING SEQUENCE
; ----------------
; result = gal_raDec(gLong, gLat)
;
; PARAMETERS
; ----------
; gLong: float
;     the galactic longitude (l) in degrees
; gLat: float
;     the galactic latitude (b) in degrees
;
; OUTPUTS
; -------
; raDec: list
;     the right ascension and declination as a tuple i.e. right
;     ascension = result[0], declination = result[1], in degrees
;-
  gLong *= !dtor   ; convert coordinates to radians
  gLat *= !dtor    ; convert coordinates to radians
  gLongLat = [ [cos(gLat)*cos(gLong)] ,$   ; vectorize (l,b)
               [cos(gLat)*sin(gLong)] ,$
               [           sin(gLat)]  ]
  rotMatrix = [ [-0.054876,  0.494109, -0.867666],$ ; get rotation matrix
                [-0.873437, -0.444830, -0.198076],$
                [-0.483835,  0.746982,  0.455984] ]
  raDec = rotMatrix ## gLongLat           ; rotate (l,b) -> (ra,dec)
  ra = atan(raDec[1], raDec[0])*!radeg    ; unpack vector and degree-ify
  dec = asin(raDec[2])*!radeg
  raDec = [ra, dec]
  return, raDec
END
PRO power_grab, fileTag, param, locFreq, diodeON, diodeOFF, Tsys, calib=calib
;+
; OVERVIEW
; --------
; will grab data from leuschner using given parameters
;
; CALLING SEQUENCE
; ----------------
; power_grab, fileTag, nSpectra, locFreq, diodeON, diodeOFF, Tsys, /calib
;
; PARAMETERS
; ----------
; fileTag: string
;     how you want your filenames to be labeled. Will append '_on.fits'
;     and '_off.fits' at the end
; param: structure
;     the structure with tags filename, nspec, lonra, latdec, and system
;     to be filled as specified by leuschner_rx
; locFreq: double
;     the desired local oscillation frequency
;
; KEYWORDS
; --------
; calib: any
;     if set, will print out the system temperature in kelvin and make plots
;
; OUTPUTS
; -------
; diodeON: structure
;     the structure from leuschner_rx with the diode on
; diodeOFF: structure
;     the structure from leuschner_rx with the diode off
;-
  result = set_lhp(freq=locFreq, amp=19.9)         ; set the local oscillator
  noise, /on   ; get data with diode on
  WAIT, 8      ; wait for the diode to turn on
  result = leuschner_rx(fileTag+'_on.fits',$       ; set filename
                        param.nspec, param.lonra,$ ; set parameters
                        param.latdec, param.system)
  noise, /off  ; get data with diode off
  WAIT, 8      ; wait for the diode to turn off
  result = leuschner_rx(fileTag+'_off.fits',$      ; set filename
                        param.nspec, param.lonra,$ ; set parameters
                        param.latdec, param.system)
  diodeON = mrdfits(fileTag+'_on.fits', param.nspec, hON)  ; unpack fits files
  diodeOFF = mrdfits(fileTag+'_off.fits', param.nspec, hOFF)
  IF keyword_set(calib) THEN BEGIN                 ; check if want calibration
     tempON = total(diodeON.auto0_real)            ; get on temp
     tempOFF = total(diodeOFF.auto0_real)          ; get off temp
  ENDIF
  Tsys = (total(tempOFF)/total(tempON - tempOFF))*300
END
