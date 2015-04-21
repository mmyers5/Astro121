PRO loop_da_loop
;+
;-
  lRange = findgen(900)*.10    ;get longitude range
  vel = []
  FOR i=0, 899 DO BEGIN
     param = {lonra:lRange[i], latdec:0}        ; generate parameters 
     temp = doppler_it(param, systime(/JULIAN)) ; grab velocity
     vel = [vel, temp]                          ; append to velocity array
  ENDFOR
  vSun = 220                    ; sun velocity in km/s
  rSun = 8.5                    ; sun distance form gc in kpc
  lRange *= !dtor
  rRange = 8.5*tan(lRange)
  plot, rRange, (vel/(rSun*sin(lRange))) + (vSun/rSun), xrange=[200,800],/xstyle, /ystyle
  ;plot, lRange*!radeg, vel, /xstyle, /ystyle, xrange=[0,1]
END

FUNCTION doppler_it, param, jDay
;+
; OVERVIEW
; --------
; will doppler shift spectra
;
; CALLING SEQUENCE
; ----------------
; doppler_it, param, jDay
;
; PARAMETERS
; ----------
; param: structure
;     the structure with tags filename, nspec, lonra, latdec, and system
;     to be filled as specified by leuschner_rx
; jDay: float
;     the julian day of the observation
;
; OUTPUTS
; -------
; deltaFreq: float
;     the doppler shifted frequency
;-
  nlat = 37.8732     ; set latitude and longitude of leuschner
  wlong = 122.2573
  ; get right ascension and declination in degrees
  raDec = gal_raDec(param.lonra, param.latdec)
  ra=raDec[0]
  dec = raDec[1]
  vel = (ugdoppler(ra, dec, jDay, nlat=nlat, wlong=wlong))[3]
  deltaFreq = (1420.4d6)*(3d8)/vel
  return, deltaFreq
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
PRO power_grab, fileTag, param, locFreq, diodeON, diodeOFF, calib=calib
;+
; OVERVIEW
; --------
; will grab data from leuschner using given parameters
;
; CALLING SEQUENCE
; ----------------
; power_grab, fileTag, nSpectra, locFreq, diodeON, diodeOFF, /calib
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
  ;result = set_lhp(freq=locFreq, amp=19.9)         ; set the local oscillator
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
     plot, diodeON.auto0_real
     oplot, diodeOFF.auto0_real, color=!magenta    ; shout out to darkstar
  ENDIF
END
