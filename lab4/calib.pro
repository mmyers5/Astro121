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
  result = set_lhp(freq=locFreq, amp=19.9)         ; set the local oscillator
  noise, /on   ; get data with diode on
  WAIT, 8     ; wait for the diode to turn on
  result = leuschner_rx(fileTag+'_on.fits',$       ; set filename
                        param.nspec, param.lonra,$ ; set parameters
                        param.latdec, param.system)
  noise, /off  ; get data with diode off
  WAIT, 8     ; wait for the diode to turn off
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
